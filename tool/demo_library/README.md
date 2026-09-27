# Demo library

Generates a Sheetopia library for promotional screenshots. Everything in it is safe to publish:

- every work is in the public domain (all composers died well over 100 years ago, or the piece is
  traditional/anonymous),
- every PDF is engraved from the LilyPond sources in `ly/`, so no publisher's edition is reproduced either,
- no personal data, no third party branding, no real people.

## Build

Requires `lilypond` in `PATH` (tested with 2.26).

```shell
./build.py                 # -> out/sheetopia-demo-library.zip
./build.py --clean         # re-engrave every score
./build.py -o /tmp/lib.zip
./build.py --now 2026-09-27T19:30   # end the practice history at a fixed local time
```

Import the archive through *Settings > Import/Export > Import*. Use *Delete local data* first to get a clean library.

The archive uses the same layout the app's own export writes: a `.sheetopia`
marker, one JSON file per entity (`tags.json`, `scores.json`, `setlists.json`, `exercise_categories.json`,
`exercises.json`, `practice_routines.json`, `practice_records.json`) and `scores/<id>/score.pdf`.

IDs come from a fixed UUID namespace, timestamps from a fixed reference date. Practice records are the exception: they
end at `--now` so *Practiced today* and routine progress show up. Same `--now`, same archive byte for byte.
Re-importing updates existing items instead of duplicating them.

## Contents

19 scores across 7 instruments (piano, voice, guitar, violin, cello, flute, trumpet) and 8 genres, 8 coloured tags, 5
setlists, and 6 scores carrying handwritten-looking annotations. Two scores are multi-page so page turning can be shown.

Practice: 6 exercise-only scores (scales, arpeggios, cadences, chromatic scale, violin bowing), 4 of them annotated, 14 exercises in 4
categories with 4 exercise tags, 5 routines, and six weeks of practice records. Today the *Daily piano* routine is done
up to its fourth exercise.

Scores are dated so the library grid opens on the Bach prelude, `days` in `library.py` controls that order.

## Layout

| file             | purpose                                                   |
|------------------|-----------------------------------------------------------|
| `ly/`            | LilyPond sources, one per score, sharing `ly/common.ily`  |
| `library.py`     | scores, tags, setlists, annotations, practice content     |
| `annotations.py` | freehand stroke generation in the app's stroke format     |
| `strokes/`       | strokes drawn in the app, copied from an export           |
| `build.py`       | engraves the PDFs and writes the archive                  |

`test/repositories/demo_library_test.dart` imports the built archive through the app's real import path and checks it
lands correctly. It skips when the archive has not been built.

## Changing the content

- **Metadata, tags, setlists, ordering**: `library.py`.
- **A new score**: add `ly/<name>.ly` and an entry with the matching `source` to
  `SCORES`, or to `EXERCISE_SCORES` for a score only an exercise uses.
- **Practice**: `EXERCISES`, `ROUTINES`, and `HISTORY`/`AD_HOC` for how often each is practiced.
- **Annotations**: coordinates are normalized to the page. LilyPond puts the first system near `y=0.16` with roughly
  `0.10` between systems, so marks are easy to place by eye; rebuild and check the result before committing.
