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
    return {
        0: [
            ann.stroke(ann.ellipse(rng, 0.305, 0.172, 0.024, 0.018), ann.RED),
            ann.stroke(ann.line(rng, 0.100, 0.405, 0.560, 0.405, segments=20),
                       ann.HIGHLIGHTER, ann.HIGHLIGHTER_WIDTH),
            ann.stroke(ann.bracket(rng, 0.048, 0.505, 0.589), ann.BLUE),
            ann.stroke(ann.caret(rng, 0.640, 0.268), ann.RED),
        ],
        1: [
            ann.stroke(ann.wave(rng, 0.150, 0.470, 0.274, cycles=6), ann.RED),
            ann.stroke(ann.ellipse(rng, 0.720, 0.188, 0.026, 0.019), ann.BLUE),
        ],
    }


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
        "instruments": ["Piano"],
        "genres": ["Baroque"],
        "tags": ["recital", "practice"],
        "notes": "Keep the sixteenths perfectly even - no accent on the top note.\n"
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
        "title": "Menuett in G, BWV Anh. 114",
        "composer": "Christian Petzold",
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
        "title": "Kanon in D",
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
        "title": "Prélude in A, op. 28 Nr. 7",
        "composer": "Frédéric Chopin",
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
        "title": "Hanon: Übung Nr. 1",
        "composer": "Charles-Louis Hanon",
        "instruments": ["Piano"],
        "genres": ["Etude"],
        "tags": ["warmup", "practice"],
        "notes": "Five minutes before every session. Metronome from 60 upwards.",
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
    ("Warm-up Routine", 2, [
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
