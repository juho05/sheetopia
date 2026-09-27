\version "2.26.0"
\include "common.ily"

\header {
  title = "Greensleeves"
  subtitle = "English folk tune, 16th century"
  composer = "Traditional"
  tagline = ##f
}

harmonies = \chordmode {
  \partial 8 s8
  a2.:m | c2. | g2. | e2.:7 |
  a2.:m | c2. | e2.:7 | a2.:m |
  c2. | a2.:m | e2.:7 | c2. |
  a2.:m | e2.:7 | e2.:7 | a2.:m |
}

melody = {
  \clef treble
  \key a \minor
  \time 6/8
  \tempo "Andante"

  \partial 8 a'8 |
  c''4 d''8 e''8. fis''16 e''8 |
  d''4 b'8 g'8. a'16 b'8 |
  c''4 a'8 a'8. gis'16 a'8 |
  b'4 gis'8 e'4 a'8 |

  c''4 d''8 e''8. fis''16 e''8 |
  d''4 b'8 g'8. a'16 b'8 |
  c''8. b'16 a'8 gis'8. fis'16 gis'8 |
  a'4. a'4 g''8 |

  g''4. f''8. e''16 d''8 |
  c''4 a'8 a'8. gis'16 a'8 |
  b'4 gis'8 e'4 g''8 |
  g''4. f''8. e''16 d''8 |

  c''4 a'8 a'8. gis'16 a'8 |
  b'4 gis'8 e'4 e''8 |
  c''8. b'16 a'8 gis'8. fis'16 gis'8 |
  a'2.\fermata |
  \bar "|."
}

text = \lyricmode {
  A -- las, my love, you do me wrong
  to cast me off dis -- cour -- teous -- ly.
  For I have loved you so long,
  de -- light -- ing in your com -- pa -- ny.
  Green -- sleeves was all my joy,
  Green -- sleeves was my de -- light,
  Green -- sleeves was my heart of gold,
  and who but my la -- dy Green -- sleeves.
}

\score {
  <<
    \new ChordNames \harmonies
    \new Staff = "melody" \melody
    \addlyrics \text
  >>
  \layout { }
}