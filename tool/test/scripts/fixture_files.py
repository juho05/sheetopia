#!/usr/bin/env python3
"""Generated E2E test files.

  fixture_files.py tinted <out.pdf>
  fixture_files.py large-library <demo-library.zip> <out.zip> <count>
"""
import json
import sys
import uuid
import zipfile

PAGE_W, PAGE_H = 595, 842


def pdf(pages):
    """pages: content streams (bytes), one A4 page each, Helvetica as /F1."""
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        None,
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    kids = []
    for content in pages:
        objects.append(b"<< /Length %d >>\nstream\n" % len(content) + content + b"\nendstream")
        objects.append(
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] "
            b"/Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>"
            % (PAGE_W, PAGE_H, len(objects))
        )
        kids.append(b"%d 0 R" % len(objects))
    objects[1] = b"<< /Type /Pages /Kids [%s] /Count %d >>" % (b" ".join(kids), len(kids))

    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for i, body in enumerate(objects, 1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % i + body + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    for offset in offsets:
        out += b"%010d 00000 n \n" % offset
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objects) + 1, xref)
    return bytes(out)


def text(x, y, size, s):
    return b"BT /F1 %d Tf %d %d Td (%s) Tj ET\n" % (size, x, y, s.encode("ascii"))


def tinted_page(number):
    # Cream paper, content inside 20% margins on every side.
    left, right, top, bottom = 119, 476, 674, 168
    c = bytearray(b"0.96 0.92 0.80 rg 0 0 %d %d re f\n0 0 0 rg 0 0 0 RG 0.8 w\n" % (PAGE_W, PAGE_H))
    c += text(left, top - 18, 18, "Tinted margins, page %d" % number)
    staff_top = top - 50
    while staff_top - 32 >= bottom:
        for line in range(5):
            y = staff_top - line * 8
            c += b"%d %d m %d %d l S\n" % (left, y, right, y)
        for x in (left, (left + right) // 2, right):
            c += b"%d %d m %d %d l S\n" % (x, staff_top, x, staff_top - 32)
        for k in range(8):
            x = left + 20 + k * 40
            y = staff_top - 4 - ((k * 3 + number) % 7) * 4
            c += b"%d %d 9 7 re f\n" % (x, y - 3)
        staff_top -= 76
    c += text(left, bottom, 10, "Sheetopia E2E fixture")
    return bytes(c)


def tinted(out):
    with open(out, "wb") as f:
        f.write(pdf([tinted_page(1), tinted_page(2)]))


def large_library(demo, out, count):
    namespace = uuid.UUID("5d0f6c5e-3a54-4f3e-9a8e-2b8c6f1e0a01")
    with zipfile.ZipFile(demo) as src, zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as dst:
        scores = json.loads(src.read("scores.json"))
        for info in src.infolist():
            if info.filename != "scores.json":
                dst.writestr(info, src.read(info))
        for i in range(1, count + 1):
            sid = str(uuid.uuid5(namespace, "bulk-%d" % i))
            title = "Bulk score %03d" % i
            scores.append({
                "id": sid,
                "title": title,
                "fileType": "pdf",
                "fileUpdatedAt": "2026-01-01T12:00:00.000Z",
                "metadataUpdatedAt": "2026-01-01T12:00:00.000Z",
                "tagIds": [],
                "type": "score",
                "metadata": {
                    "composer": "", "arranger": "", "partOf": "", "musicalKey": "",
                    "source": "", "sourceLink": "", "notes": "", "difficulty": 0,
                    "instruments": [], "genres": [], "annotations": {},
                },
            })
            dst.writestr("scores/%s/score.pdf" % sid, pdf([text(100, 700, 24, title)]))
        dst.writestr("scores.json", json.dumps(scores, indent=2))


if __name__ == "__main__":
    match sys.argv[1:]:
        case ["tinted", out]:
            tinted(out)
        case ["large-library", demo, out, count]:
            large_library(demo, out, int(count))
        case _:
            sys.exit(__doc__)
