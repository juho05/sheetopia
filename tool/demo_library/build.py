#!/usr/bin/env python3
"""Build an importable Sheetopia library from the LilyPond sources in ly/.

    ./build.py [-o OUTPUT.zip]

Produces the same archive layout that Settings > Import/Export writes, so the
result can be imported straight through Settings > Import.
"""

import argparse
import datetime as dt
import json
import os
import random
import shutil
import subprocess
import sys
import uuid
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import library  # noqa: E402

ROOT = os.path.dirname(os.path.abspath(__file__))
LY_DIR = os.path.join(ROOT, "ly")
BUILD_DIR = os.path.join(ROOT, "build")
DEFAULT_OUTPUT = os.path.join(ROOT, "out", "sheetopia-demo-library.zip")

# Fixed namespace and reference date keep rebuilds byte for byte identical, so
# reimporting an updated library updates the existing scores instead of adding
# duplicates.
NAMESPACE = uuid.UUID("6f1d0f5a-3d2e-4b3f-9a71-2b8c5d4e7f10")
REFERENCE = dt.datetime(2026, 7, 30, 18, 0, 0, tzinfo=dt.timezone.utc)
SEED = 20260730

A4_ASPECT = 297.0 / 210.0


def ident(kind, name):
    return str(uuid.uuid5(NAMESPACE, f"{kind}:{name}"))


def timestamp(days_ago, hour_offset=0):
    return (REFERENCE - dt.timedelta(days=days_ago, hours=hour_offset)).strftime(
        "%Y-%m-%dT%H:%M:%S.000Z"
    )


def engrave(sources):
    os.makedirs(BUILD_DIR, exist_ok=True)
    for source in sources:
        ly = os.path.join(LY_DIR, f"{source}.ly")
        if not os.path.exists(ly):
            raise SystemExit(f"missing LilyPond source: {ly}")
        pdf = os.path.join(BUILD_DIR, f"{source}.pdf")
        if os.path.exists(pdf) and os.path.getmtime(pdf) > os.path.getmtime(ly):
            continue
        print(f"engraving {source}")
        result = subprocess.run(
            ["lilypond", "--silent", "-o", os.path.join(BUILD_DIR, source), ly],
            cwd=LY_DIR,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            sys.stderr.write(result.stderr)
            raise SystemExit(f"lilypond failed for {source}")


def build_metadata():
    tags = [
        {
            "id": ident("tag", key),
            "name": name,
            "color": color,
            "updatedAt": timestamp(60),
        }
        for key, name, color in library.TAGS
    ]

    rng = random.Random(SEED)
    scores = []
    for entry in library.SCORES:
        source = entry["source"]
        marks = entry.get("annotations")
        strokes = marks(rng) if marks else {}
        scores.append({
            "id": ident("score", source),
            "title": entry["title"],
            "fileType": "pdf",
            "fileUpdatedAt": timestamp(entry["days"], hour_offset=2),
            "metadataUpdatedAt": timestamp(entry["days"]),
            "tagIds": [ident("tag", t) for t in entry["tags"]],
            "metadata": {
                "composer": entry["composer"],
                "notes": entry.get("notes") or "",
                "instruments": entry["instruments"],
                "genres": entry["genres"],
                "annotations": {str(page): s for page, s in sorted(strokes.items())},
            },
        })

    setlists = [
        {
            "id": ident("setlist", name),
            "name": name,
            "scoreIds": [ident("score", s) for s in sources],
            "updatedAt": timestamp(days),
        }
        for name, days, sources in library.SETLISTS
    ]

    return tags, scores, setlists


def write_archive(output, tags, scores, setlists):
    os.makedirs(os.path.dirname(output) or ".", exist_ok=True)
    if os.path.exists(output):
        os.remove(output)

    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(".sheetopia", "")
        zf.writestr("tags.json", json.dumps(tags, ensure_ascii=False))
        zf.writestr("scores.json", json.dumps(scores, ensure_ascii=False))
        zf.writestr("setlists.json", json.dumps(setlists, ensure_ascii=False))
        for entry, score in zip(library.SCORES, scores):
            pdf = os.path.join(BUILD_DIR, f"{entry['source']}.pdf")
            zf.write(pdf, f"scores/{score['id']}/score.pdf")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--clean", action="store_true",
                        help="re-engrave every score from scratch")
    args = parser.parse_args()

    if args.clean and os.path.isdir(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)

    if shutil.which("lilypond") is None:
        raise SystemExit("lilypond not found in PATH")

    sources = [e["source"] for e in library.SCORES]
    if len(set(sources)) != len(sources):
        raise SystemExit("duplicate source in library.SCORES")

    engrave(sources)
    tags, scores, setlists = build_metadata()
    write_archive(args.output, tags, scores, setlists)

    annotated = sum(1 for s in scores if s["metadata"]["annotations"])
    size = os.path.getsize(args.output) / 1024
    print(f"\n{args.output}")
    print(f"  {len(scores)} scores ({annotated} annotated), "
          f"{len(tags)} tags, {len(setlists)} setlists, {size:.0f} KiB")


if __name__ == "__main__":
    main()
