"""Content definition for the Sheetopia demo library.

Everything here is public domain: the works themselves are long out of
copyright and every PDF is engraved from scratch from the LilyPond sources in
ly/, so no publisher's edition is reproduced.
"""

import annotations as ann

TAGS = [
    ("recital", "Recital", 0xFF7E57C2),
    ("favourites", "Favourites", 0xFFEC407A),
    ("practice", "Practice", 0xFF42A5F5),
    ("memorized", "Memorized", 0xFF66BB6A),
    ("tolearn", "To learn", 0xFFEF5350),
    ("warmup", "Warm-up", 0xFFFFA726),
    ("tablature", "Tablature", 0xFFAB47BC),
    ("christmas", "Christmas", 0xFF26A69A),
]


# --- annotations -------------------------------------------------------------
# Coordinates are normalized to the page (0..1) and were read off the engraved
# PDFs, so they sit on real staves. A staff is about 0.024 tall; the first
# system is indented to x=0.14 for the clef and brace, later systems start at
# x=0.07, and the right edge is at x=0.92. Highlighter and circle marks take the
# centre of a staff, underlines go below the lowest staff of a system, and
# brackets go into the left margin next to the system they belong to.

def _prelude_marks(rng):
    # systems at 0.161/0.212, 0.277/0.328, 0.393/0.444, 0.510/0.560
    # The replaced generated shapes still draw from rng so later scores keep their jitter.
    ann.ellipse(rng, 0.305, 0.172, 0.024, 0.018)
    highlight = ann.stroke(ann.line(rng, 0.100, 0.405, 0.560, 0.405, segments=20),
                           ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH)
    bracket = ann.stroke(ann.bracket(rng, 0.048, 0.505, 0.589), ann.BLUE)
    ann.caret(rng, 0.640, 0.268)
    ann.wave(rng, 0.150, 0.470, 0.274, cycles=6)
    ann.ellipse(rng, 0.720, 0.188, 0.026, 0.019)

    drawn = ann.hand_drawn("prelude_c_bwv846")
    return {0: [highlight, bracket] + drawn[0], 1: drawn[1]}


def _fuer_elise_marks(rng):
    # systems at 0.169/0.222, 0.293/0.346
    return {
        0: [
            ann.stroke(ann.ellipse(rng, 0.330, 0.180, 0.021, 0.016), ann.RED),
            ann.stroke(ann.line(rng, 0.090, 0.305, 0.520, 0.305, segments=18),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
            ann.stroke(ann.caret(rng, 0.430, 0.266), ann.BLUE),
            ann.stroke(ann.check(rng, 0.840, 0.098), ann.GREEN),
        ],
    }


def _menuett_marks(rng):
    # systems at 0.179/0.232, 0.303/0.356
    return {
        0: [
            ann.stroke(ann.bracket(rng, 0.112, 0.175, 0.260), ann.BLUE),
            ann.stroke(ann.ellipse(rng, 0.560, 0.191, 0.023, 0.017), ann.RED),
            ann.stroke(ann.check(rng, 0.855, 0.100), ann.GREEN),
        ],
    }


def _entertainer_marks(rng):
    # page 0 systems at 0.182/0.236, 0.315/0.369; page 1 at 0.088/0.142
    return {
        0: [
            ann.stroke(ann.line(rng, 0.165, 0.194, 0.470, 0.194, segments=16),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
            ann.stroke(ann.ellipse(rng, 0.232, 0.170, 0.085, 0.016), ann.RED),
            ann.stroke(ann.bracket(rng, 0.048, 0.310, 0.396), ann.BLUE),
        ],
        1: [
            ann.stroke(ann.wave(rng, 0.160, 0.520, 0.192, cycles=7), ann.BLUE),
        ],
    }


def _kanon_marks(rng):
    # systems at 0.167/0.221, 0.291/0.345
    return {
        0: [
            ann.stroke(ann.ellipse(rng, 0.465, 0.179, 0.024, 0.018), ann.BLUE),
            ann.stroke(ann.line(rng, 0.090, 0.303, 0.560, 0.303, segments=18),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
        ],
    }


def _hanon_marks(rng):
    # systems at 0.185/0.238, 0.309/0.357
    return {
        0: [
            ann.stroke(ann.check(rng, 0.850, 0.096), ann.GREEN),
            ann.stroke(ann.bracket(rng, 0.112, 0.181, 0.265), ann.RED),
        ],
    }


# --- scores ------------------------------------------------------------------
# `days` drives the grid order: the library sorts by most recently touched, so a
# smaller number puts the score further to the front.

SCORES = [
    {
        "source": "prelude_c_bwv846",
        "title": "Praeludium I in C, BWV 846",
        "composer": "Johann Sebastian Bach",
        "published_in": "Das Wohltemperierte Klavier I",
        "instruments": ["Piano"],
        "genres": ["Baroque"],
        "tags": ["recital", "practice"],
        "notes": "Keep the sixteenths perfectly even. No accent on the top note.\n"
                 "Pedal changes on every bar, half pedal from bar 21.",
        "days": 0,
        "annotations": _prelude_marks,
    },
    {
        "source": "fuer_elise",
        "title": "Für Elise, WoO 59",
        "composer": "Ludwig van Beethoven",
        "instruments": ["Piano"],
        "genres": ["Classical"],
        "tags": ["recital", "memorized"],
        "notes": "Poco moto - resist the urge to rush the A section.",
        "days": 1,
        "annotations": _fuer_elise_marks,
    },
    {
        "source": "the_entertainer",
        "title": "The Entertainer",
        "composer": "Scott Joplin",
        "instruments": ["Piano"],
        "genres": ["Ragtime"],
        "tags": ["recital", "tolearn"],
        "notes": "Joplin's own marking: \"Not fast\". The left hand stays strictly in time.",
        "days": 2,
        "annotations": _entertainer_marks,
    },
    {
        "source": "menuett_g_bwv_anh114",
        "title": "Minuet in G, BWV Anh. 114",
        "composer": "Christian Petzold",
        "published_in": "Notenbüchlein für Anna Magdalena Bach",
        "instruments": ["Piano"],
        "genres": ["Baroque"],
        "tags": ["practice", "memorized"],
        "notes": "Both repeats observed. Ornaments on the second time only.",
        "days": 3,
        "annotations": _menuett_marks,
    },
    {
        "source": "greensleeves",
        "title": "Greensleeves",
        "composer": "Traditional",
        "instruments": ["Voice", "Guitar"],
        "genres": ["Folk"],
        "tags": [],
        "notes": "Capo 2 works nicely for a lower voice.",
        "days": 4,
    },
    {
        "source": "kanon_in_d",
        "title": "Canon in D",
        "composer": "Johann Pachelbel",
        "instruments": ["Violin", "Cello"],
        "genres": ["Baroque"],
        "tags": ["favourites"],
        "notes": "Cello can loop the ground bass for as long as the piece needs.",
        "days": 6,
        "annotations": _kanon_marks,
    },
    {
        "source": "romanza",
        "title": "Romanza",
        "composer": "Anonymous",
        "instruments": ["Guitar"],
        "genres": ["Romantic"],
        "tags": ["tablature", "memorized"],
        "notes": "Free stroke throughout, thumb stays on the bass string.",
        "days": 7,
    },
    {
        "source": "eine_kleine_nachtmusik",
        "title": "Eine kleine Nachtmusik, KV 525",
        "composer": "Wolfgang Amadeus Mozart",
        "published_in": "Serenade No. 13 in G, KV 525",
        "instruments": ["Violin"],
        "genres": ["Classical"],
        "tags": ["recital"],
        "notes": None,
        "days": 9,
    },
    {
        "source": "air_bwv1068",
        "title": "Air, BWV 1068",
        "composer": "Johann Sebastian Bach",
        "published_in": "Orchestral Suite No. 3 in D, BWV 1068",
        "instruments": ["Violin", "Piano"],
        "genres": ["Baroque"],
        "tags": ["favourites"],
        "notes": "Long bow, no vibrato on the opening note.",
        "days": 11,
    },
    {
        "source": "jesu_bleibet_meine_freude",
        "title": "Jesu, bleibet meine Freude, BWV 147",
        "composer": "Johann Sebastian Bach",
        "published_in": "Cantata BWV 147",
        "instruments": ["Piano"],
        "genres": ["Baroque"],
        "tags": ["favourites", "tolearn"],
        "notes": "Triplets flowing, never plodding.",
        "days": 13,
    },
    {
        "source": "amazing_grace",
        "title": "Amazing Grace",
        "composer": "Traditional",
        "instruments": ["Voice"],
        "genres": ["Hymn"],
        "tags": [],
        "notes": None,
        "days": 15,
    },
    {
        "source": "solfeggietto",
        "title": "Solfeggietto in C minor, H 220",
        "composer": "Carl Philipp Emanuel Bach",
        "instruments": ["Piano"],
        "genres": ["Baroque"],
        "tags": ["practice", "tolearn"],
        "notes": "Hands alternate - practise each hand alone at half tempo first.",
        "days": 17,
    },
    {
        "source": "scarborough_fair",
        "title": "Scarborough Fair",
        "composer": "Traditional",
        "instruments": ["Voice", "Guitar"],
        "genres": ["Folk"],
        "tags": [],
        "notes": None,
        "days": 19,
    },
    {
        "source": "prelude_a_op28_7",
        "title": "Prelude in A, op. 28 No. 7",
        "composer": "Frédéric Chopin",
        "published_in": "24 Preludes, op. 28",
        "instruments": ["Piano"],
        "genres": ["Romantic"],
        "tags": ["favourites", "memorized"],
        "notes": "Sixteen bars, one single phrase. The left hand stays under the melody.",
        "days": 21,
    },
    {
        "source": "ode_an_die_freude",
        "title": "Ode an die Freude",
        "composer": "Ludwig van Beethoven",
        "published_in": "Symphony No. 9, op. 125",
        "instruments": ["Trumpet"],
        "genres": ["Classical"],
        "tags": [],
        "notes": "Transposed part - sounds a major second lower than written.",
        "days": 24,
    },
    {
        "source": "ah_vous_dirai_je_maman",
        "title": "Ah vous dirai-je, maman",
        "composer": "Wolfgang Amadeus Mozart",
        "instruments": ["Flute", "Piano"],
        "genres": ["Classical"],
        "tags": ["practice"],
        "notes": None,
        "days": 27,
    },
    {
        "source": "danny_boy",
        "title": "Danny Boy",
        "composer": "Traditional",
        "instruments": ["Voice"],
        "genres": ["Folk"],
        "tags": [],
        "notes": None,
        "days": 30,
    },
    {
        "source": "hanon_uebung_1",
        "title": "Hanon: Exercise No. 1",
        "composer": "Charles-Louis Hanon",
        "published_in": "The Virtuoso Pianist, Part I",
        "instruments": ["Piano"],
        "genres": ["Etude"],
        "tags": ["warmup", "practice"],
        "notes": "Five minutes before every session. Start at 60 bpm and work upwards.",
        "days": 34,
        "annotations": _hanon_marks,
    },
    {
        "source": "stille_nacht",
        "title": "Stille Nacht, heilige Nacht",
        "composer": "Franz Xaver Gruber",
        "instruments": ["Voice"],
        "genres": ["Christmas"],
        "tags": ["christmas"],
        "notes": None,
        "days": 38,
    },
]

SETLISTS = [
    ("Spring Recital", 1, [
        "prelude_c_bwv846",
        "menuett_g_bwv_anh114",
        "fuer_elise",
        "romanza",
        "eine_kleine_nachtmusik",
        "the_entertainer",
    ]),
    ("Sunday Set", 5, [
        "kanon_in_d",
        "jesu_bleibet_meine_freude",
        "air_bwv1068",
        "prelude_a_op28_7",
    ]),
    ("Studies", 2, [
        "hanon_uebung_1",
        "ah_vous_dirai_je_maman",
        "solfeggietto",
    ]),
    ("Folk Session", 12, [
        "greensleeves",
        "scarborough_fair",
        "danny_boy",
        "amazing_grace",
    ]),
    ("Christmas Eve", 40, [
        "stille_nacht",
        "amazing_grace",
        "jesu_bleibet_meine_freude",
    ]),
]


# --- practice ----------------------------------------------------------------
# Exercise scores belong to an exercise and are hidden from the library. They
# are engraved from ly/ like the library scores.

def _scales_major_marks(rng):
    # piano systems at 0.173/0.242, 0.375/0.428, 0.564/0.627, 0.759/0.812
    return {
        0: [
            ann.stroke(ann.ellipse(rng, 0.283, 0.186, 0.022, 0.020), ann.RED),
            ann.stroke(ann.check(rng, 0.905, 0.232), ann.GREEN),
            ann.stroke(ann.bracket(rng, 0.105, 0.560, 0.656), ann.BLUE),
            ann.stroke(ann.line(rng, 0.200, 0.771, 0.880, 0.771, segments=20),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
        ],
    }


def _cadences_marks(rng):
    # piano systems at 0.161/0.214, 0.291/0.344, 0.428/0.481
    return {
        0: [
            ann.stroke(ann.ellipse(rng, 0.405, 0.178, 0.024, 0.024), ann.BLUE),
            ann.stroke(ann.check(rng, 0.925, 0.150), ann.GREEN),
            ann.stroke(ann.wave(rng, 0.520, 0.910, 0.556, cycles=6), ann.RED),
        ],
    }


def _chromatic_marks(rng):
    # piano systems at 0.157/0.217, 0.287/0.352
    return {
        0: [
            ann.stroke(ann.line(rng, 0.400, 0.169, 0.910, 0.169, segments=20),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
            ann.stroke(ann.ellipse(rng, 0.128, 0.279, 0.018, 0.018), ann.RED),
        ],
    }


def _open_strings_marks(rng):
    # systems at 0.185, 0.257, 0.336
    return {
        0: [
            ann.stroke(ann.bracket(rng, 0.055, 0.328, 0.370), ann.BLUE),
            ann.stroke(ann.ellipse(rng, 0.222, 0.212, 0.022, 0.022), ann.RED),
        ],
    }


EXERCISE_SCORES = [
    {"source": "scales_major", "title": "Major Scales", "instruments": ["Piano"], "days": 20,
     "annotations": _scales_major_marks},
    {"source": "scales_minor", "title": "Minor Scales", "instruments": ["Piano"], "days": 20},
    {"source": "arpeggios", "title": "Arpeggios", "instruments": ["Piano"], "days": 18},
    {"source": "cadences", "title": "Cadences", "instruments": ["Piano"], "days": 16,
     "annotations": _cadences_marks},
    {"source": "chromatic_scale", "title": "Chromatic Scale", "instruments": ["Piano"], "days": 20,
     "annotations": _chromatic_marks},
    {"source": "open_strings", "title": "Open Strings", "instruments": ["Violin"], "days": 14,
     "annotations": _open_strings_marks},
]

EXERCISE_TAGS = [
    ("daily", "Daily", 0xFF5C6BC0),
    ("slow", "Slow practice", 0xFF26C6DA),
    ("tricky", "Tricky spots", 0xFFFF7043),
    ("hands_separate", "Hands separately", 0xFF9CCC65),
]

CATEGORIES = [
    ("warmup", "Warm-up"),
    ("technique", "Technique"),
    ("repertoire", "Repertoire"),
    ("reading", "Reading"),
]

EXERCISES = [
    {
        "key": "finger_independence",
        "name": "Finger independence",
        "category": "warmup",
        "instrument": "Piano",
        "tags": ["daily"],
        "description": "Hold down C D E F G with the right hand. Lift and tap each finger "
                       "ten times while the others stay down, then switch hands.",
        "scores": [],
        "days": 22,
    },
    {
        "key": "chromatic",
        "name": "Chromatic scale",
        "category": "warmup",
        "instrument": "Piano",
        "tags": ["daily"],
        "description": "Two octaves, hands together. Keep the hand close to the black keys.",
        "scores": ["chromatic_scale"],
        "bpm": 100,
        "days": 20,
    },
    {
        "key": "hanon",
        "name": "Hanon No. 1",
        "category": "warmup",
        "instrument": "Piano",
        "tags": ["daily"],
        "description": "Start at 60 and add 4 bpm once every repetition is clean.",
        "source": "The Virtuoso Pianist, Part I",
        "scores": ["hanon_uebung_1"],
        "bpm": 108,
        "days": 21,
    },
    {
        "key": "scales",
        "name": "Scales",
        "category": "technique",
        "instrument": "Piano",
        "tags": ["daily"],
        "description": "Major and harmonic minor, two octaves. Alternate the keys every day.",
        "scores": ["scales_major", "scales_minor"],
        "bpm": 96,
        "days": 20,
    },
    {
        "key": "arpeggios",
        "name": "Arpeggios",
        "category": "technique",
        "instrument": "Piano",
        "tags": ["tricky", "hands_separate"],
        "description": "The thumb passes under without a bump. Hands separately until even.",
        "scores": ["arpeggios"],
        "bpm": 80,
        "days": 18,
    },
    {
        "key": "cadences",
        "name": "Cadences",
        "category": "technique",
        "instrument": "Piano",
        "tags": [],
        "description": "I IV V7 I in every key on the sheet. Say the chord names out loud.",
        "scores": ["cadences"],
        "days": 16,
    },
    {
        "key": "prelude_bars",
        "name": "Praeludium I: bars 21-35",
        "category": "repertoire",
        "instrument": "Piano",
        "tags": ["slow", "hands_separate"],
        "description": "The dominant pedal. Voice the top notes and keep the bass tied.",
        "scores": ["prelude_c_bwv846"],
        "bpm": 66,
        "days": 12,
    },
    {
        "key": "fuer_elise_b",
        "name": "Für Elise: B section",
        "category": "repertoire",
        "instrument": "Piano",
        "tags": ["slow"],
        "description": "Left hand repeated notes light, the melody sings on top.",
        "scores": ["fuer_elise"],
        "bpm": 72,
        "days": 11,
    },
    {
        "key": "entertainer_lh",
        "name": "The Entertainer: left hand",
        "category": "repertoire",
        "instrument": "Piano",
        "tags": ["hands_separate", "tricky"],
        "description": "Left hand alone, strictly in time. Prepare every jump early.",
        "scores": ["the_entertainer"],
        "bpm": 76,
        "days": 10,
    },
    {
        "key": "solfeggietto",
        "name": "Solfeggietto: slow practice",
        "category": "repertoire",
        "instrument": "Piano",
        "tags": ["slow", "tricky"],
        "description": "Half tempo, every note even. Only speed up when three runs in a row are clean.",
        "scores": ["solfeggietto"],
        "bpm": 60,
        "days": 9,
    },
    {
        "key": "sight_reading",
        "name": "Sight-reading",
        "category": "reading",
        "tags": ["daily"],
        "description": "Read one new piece a day. Keep going, never stop to fix a mistake.",
        "scores": [],
        "days": 19,
    },
    {
        "key": "rhythm_reading",
        "name": "Rhythm reading",
        "category": "reading",
        "tags": [],
        "description": "Clap the rhythm of the first line before playing it. Count out loud.",
        "scores": [],
        "days": 17,
    },
    {
        "key": "open_strings",
        "name": "Long bows on open strings",
        "category": "warmup",
        "instrument": "Violin",
        "tags": ["daily", "slow"],
        "description": "Straight bow between fingerboard and bridge, even sound from frog to tip.",
        "scores": ["open_strings"],
        "bpm": 60,
        "days": 14,
    },
    {
        "key": "kanon_bass",
        "name": "Canon: ground bass",
        "category": "repertoire",
        "instrument": "Cello",
        "tags": ["slow"],
        "description": "Loop the eight notes until the intonation settles.",
        "scores": ["kanon_in_d"],
        "bpm": 60,
        "days": 13,
    },
]

# entries are (exercise, target minutes, extra notes, default score)
ROUTINES = [
    {
        "key": "daily_piano",
        "name": "Daily piano",
        "description": "The everyday routine, about 50 minutes.",
        "days": 8,
        "entries": [
            ("finger_independence", 3, None, None),
            ("chromatic", 3, None, None),
            ("hanon", 5, "Start at 60 bpm.", None),
            ("scales", 10, None, "scales_major"),
            ("arpeggios", 5, None, None),
            ("prelude_bars", 15, "Hands separately first, then together at 50 bpm.", None),
            ("sight_reading", 10, None, None),
        ],
    },
    {
        "key": "recital_prep",
        "name": "Recital prep",
        "description": "Only the hard passages of the Spring Recital programme.",
        "days": 6,
        "entries": [
            ("hanon", 5, None, None),
            ("prelude_bars", 10, None, None),
            ("fuer_elise_b", 10, None, None),
            ("entertainer_lh", 10, "Count out loud, the offbeats stay light.", None),
            ("solfeggietto", 10, None, None),
        ],
    },
    {
        "key": "quick_warmup",
        "name": "Quick warm-up",
        "description": "Ten minutes before rehearsal.",
        "days": 15,
        "entries": [
            ("finger_independence", 2, None, None),
            ("chromatic", 3, None, None),
            ("scales", 5, "Minor keys only.", "scales_minor"),
        ],
    },
    {
        "key": "reading",
        "name": "Reading & theory",
        "description": None,
        "days": 16,
        "entries": [
            ("cadences", 10, None, None),
            ("rhythm_reading", 5, None, None),
            ("sight_reading", 15, None, None),
        ],
    },
    {
        "key": "strings",
        "name": "Strings",
        "description": "Violin and cello basics.",
        "days": 13,
        "entries": [
            ("open_strings", 10, None, None),
            ("kanon_bass", 15, None, None),
        ],
    },
]

# Practice history, relative to the build time so "Practiced today" and the
# routine progress show up. Each routine is practiced on a share of the past
# HISTORY_DAYS days, starting at a local time of day in hours.
HISTORY_DAYS = 42

HISTORY = [
    ("quick_warmup", 0.15, 7.5),
    ("daily_piano", 0.75, 18.0),
    ("recital_prep", 0.3, None),
    ("reading", 0.15, None),
    ("strings", 0.2, None),
]

# single exercises practiced outside a routine: (exercise, share of days, hour)
AD_HOC = [
    ("solfeggietto", 0.12, 12.5),
    ("entertainer_lh", 0.1, 13.0),
    ("cadences", 0.08, 12.0),
]

# today the daily routine is done up to and including this entry
TODAY_ROUTINE = "daily_piano"
TODAY_ENTRIES = 4
