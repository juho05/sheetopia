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


def iso(moment):
    return moment.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def score_model(entry, strokes, score_type, source="", tags=(), genres=()):
    return {
        "id": ident("score", entry["source"]),
        "title": entry["title"],
        "fileType": "pdf",
        "fileUpdatedAt": timestamp(entry["days"], hour_offset=2),
        "metadataUpdatedAt": timestamp(entry["days"]),
        "tagIds": [ident("tag", t) for t in tags],
        "type": score_type,
        "metadata": {
            "composer": entry.get("composer") or "",
            "source": source,
            "sourceLink": "",
            "notes": entry.get("notes") or "",
            "instruments": entry["instruments"],
            "genres": list(genres),
            "annotations": {str(page): s for page, s in sorted(strokes.items())},
        },
    }


def build_metadata():
    tags = [
        {
            "id": ident("tag", key),
            "name": name,
            "color": color,
            "type": tag_type,
            "updatedAt": timestamp(60),
        }
        for tag_type, entries in (("score", library.TAGS),
                                  ("exercise", library.EXERCISE_TAGS))
        for key, name, color in entries
    ]

    rng = random.Random(SEED)
    scores = []
    for entry in library.SCORES:
        marks = entry.get("annotations")
        strokes = marks(rng) if marks else {}
        scores.append(score_model(
            entry, strokes, "score",
            source=entry.get("published_in") or "",
            tags=entry["tags"],
            genres=entry["genres"],
        ))
    for entry in library.EXERCISE_SCORES:
        marks = entry.get("annotations")
        scores.append(score_model(entry, marks(rng) if marks else {}, "exercise"))

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


def build_practice():
    categories = [
        {
            "id": ident("category", key),
            "name": name,
            "position": position,
            "updatedAt": timestamp(30),
        }
        for position, (key, name) in enumerate(library.CATEGORIES)
    ]

    exercises = [
        {
            "id": ident("exercise", e["key"]),
            "name": e["name"],
            "categoryId": ident("category", e["category"]) if e.get("category") else None,
            "tagIds": [ident("tag", t) for t in e["tags"]],
            "scoreIds": [ident("score", s) for s in e["scores"]],
            "metadata": {
                "description": e.get("description") or "",
                "source": e.get("source") or "",
                "sourceLink": "",
                "instrument": e.get("instrument") or "",
                "targetBpm": e.get("bpm") or 0,
                "progressResetAt": "",
            },
            "updatedAt": timestamp(e["days"]),
        }
        for e in library.EXERCISES
    ]

    routines = [
        {
            "id": ident("routine", r["key"]),
            "name": r["name"],
            "metadata": {
                "description": r.get("description") or "",
                "progressResetAt": "",
            },
            "entries": [
                {
                    "id": entry_id(r["key"], i),
                    "exerciseId": ident("exercise", exercise),
                    "metadata": {
                        "extraNotes": notes or "",
                        "defaultScoreId": ident("score", default) if default else "",
                        "targetDuration": minutes * 60 * 1000,
                    },
                }
                for i, (exercise, minutes, notes, default) in enumerate(r["entries"])
            ],
            "updatedAt": timestamp(r["days"]),
        }
        for r in library.ROUTINES
    ]

    return categories, exercises, routines


def entry_id(routine, index):
    return ident("routine_entry", f"{routine}:{index}")


class History:
    """Practice records relative to `now`, a naive local datetime.

    Record ids are keyed by day offset and position, so reimporting a rebuild
    from a later day updates the records instead of adding more.
    """

    def __init__(self, now):
        self.now = now
        self.records = []
        self._day = 0
        self._index = 0

    def add(self, exercise, start, duration, routine=None, entry=None):
        end = start + duration
        self.records.append({
            "id": ident("record", f"{self._day}:{self._index}"),
            "exerciseId": ident("exercise", exercise),
            "routineId": ident("routine", routine) if routine else None,
            "routineEntryId": entry_id(routine, entry) if routine else None,
            "metadata": {
                "duration": int(duration.total_seconds()) * 1000,
                "startedAt": iso(start),
            },
            "updatedAt": iso(end),
        })
        self._index += 1
        return end

    def routine(self, rng, key, start, entries=None):
        routine = next(r for r in library.ROUTINES if r["key"] == key)
        moment = start
        for i, (exercise, minutes, _, _) in enumerate(routine["entries"][:entries]):
            if entries is None and rng.random() < 0.1:
                continue
            seconds = int(minutes * 60 * rng.uniform(0.75, 1.35))
            moment = self.add(exercise, moment, dt.timedelta(seconds=seconds), key, i)
            moment += dt.timedelta(seconds=rng.randint(10, 90))
        return moment

    def build(self):
        rng = random.Random(SEED)
        midnight = self.now.replace(hour=0, minute=0, second=0, microsecond=0)
        for days_ago in range(library.HISTORY_DAYS, 0, -1):
            self._day, self._index = days_ago, 0
            day = midnight - dt.timedelta(days=days_ago)
            if any(first <= days_ago <= last for first, last in library.BREAKS):
                continue
            start_activity = library.HISTORY_START_ACTIVITY
            activity = library.WEEKDAY_ACTIVITY[day.weekday()] * (
                start_activity
                + (1 - start_activity) * (1 - days_ago / library.HISTORY_DAYS))
            streak = any(first <= days_ago <= last for first, last in library.STREAKS)
            cursor = None
            for key, share, hour in library.HISTORY:
                forced = streak and key == library.TODAY_ROUTINE
                if rng.random() >= share * activity and not forced:
                    continue
                if hour is None:
                    start = (cursor or day + dt.timedelta(hours=19)) \
                        + dt.timedelta(minutes=rng.randint(10, 40))
                else:
                    if hour >= 17 and day.weekday() >= 5:
                        hour += library.WEEKEND_EVENING_SHIFT
                    start = day + dt.timedelta(hours=hour, minutes=rng.randint(0, 30))
                    if cursor and start < cursor:
                        start = cursor + dt.timedelta(minutes=10)
                cursor = self.routine(rng, key, start)
            for exercise, share, hour in library.AD_HOC:
                if rng.random() >= share * activity:
                    continue
                start = day + dt.timedelta(hours=hour, minutes=rng.randint(0, 20))
                self.add(exercise, start, dt.timedelta(minutes=rng.randint(6, 25)))
                break

        self._day, self._index = 0, 0
        routine = next(r for r in library.ROUTINES if r["key"] == library.TODAY_ROUTINE)
        planned = sum(m for _, m, _, _ in routine["entries"][:library.TODAY_ENTRIES])
        start = max(self.now - dt.timedelta(minutes=planned + 30), midnight)
        self.routine(random.Random(SEED + 1), library.TODAY_ROUTINE, start,
                     entries=library.TODAY_ENTRIES)
        return self.records


def check_references(scores, exercises, routines):
    score_ids = {s["id"] for s in scores}
    for e in library.EXERCISES:
        for s in e["scores"]:
            if ident("score", s) not in score_ids:
                raise SystemExit(f"exercise {e['key']} references unknown score {s}")
    keys = {e["key"] for e in library.EXERCISES}
    for r in library.ROUTINES:
        for exercise, _, _, default in r["entries"]:
            if exercise not in keys:
                raise SystemExit(f"routine {r['key']} references unknown exercise {exercise}")
            linked = next(e for e in library.EXERCISES if e["key"] == exercise)["scores"]
            if default and default not in linked:
                raise SystemExit(f"routine {r['key']} default score {default} "
                                 f"is not a score of {exercise}")


def write_archive(output, files, sources, scores):
    os.makedirs(os.path.dirname(output) or ".", exist_ok=True)
    if os.path.exists(output):
        os.remove(output)

    def put(name, data):
        info = zipfile.ZipInfo(name, REFERENCE.timetuple()[:6])
        info.compress_type = zipfile.ZIP_DEFLATED
        zf.writestr(info, data)

    with zipfile.ZipFile(output, "w") as zf:
        put(".sheetopia", "")
        for name, models in files.items():
            put(name, json.dumps(models, ensure_ascii=False))
        for source, score in zip(sources, scores):
            with open(os.path.join(BUILD_DIR, f"{source}.pdf"), "rb") as pdf:
                put(f"scores/{score['id']}/score.pdf", pdf.read())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--clean", action="store_true",
                        help="re-engrave every score from scratch")
    parser.add_argument("--now", type=dt.datetime.fromisoformat,
                        default=dt.datetime.now(),
                        help="local time the practice history ends at, "
                             "e.g. 2026-09-27T19:30 (default: now)")
    args = parser.parse_args()
    if args.now.tzinfo is not None:
        raise SystemExit("--now takes a local time without timezone")

    if args.clean and os.path.isdir(BUILD_DIR):
        shutil.rmtree(BUILD_DIR)

    if shutil.which("lilypond") is None:
        raise SystemExit("lilypond not found in PATH")

    sources = [e["source"] for e in library.SCORES + library.EXERCISE_SCORES]
    if len(set(sources)) != len(sources):
        raise SystemExit("duplicate source in library.SCORES or library.EXERCISE_SCORES")

    engrave(sources)
    tags, scores, setlists = build_metadata()
    categories, exercises, routines = build_practice()
    check_references(scores, exercises, routines)
    records = History(args.now).build()
    write_archive(args.output, {
        "tags.json": tags,
        "scores.json": scores,
        "setlists.json": setlists,
        "exercise_categories.json": categories,
        "exercises.json": exercises,
        "practice_routines.json": routines,
        "practice_records.json": records,
    }, sources, scores)

    annotated = sum(1 for s in scores if s["metadata"]["annotations"])
    size = os.path.getsize(args.output) / 1024
    print(f"\n{args.output}")
    print(f"  {len(scores)} scores ({annotated} annotated, "
          f"{len(library.EXERCISE_SCORES)} exercise only), "
          f"{len(tags)} tags, {len(setlists)} setlists, {size:.0f} KiB")
    print(f"  {len(categories)} categories, {len(exercises)} exercises, "
          f"{len(routines)} routines, {len(records)} practice records "
          f"up to {args.now:%Y-%m-%d %H:%M}")


if __name__ == "__main__":
    main()
