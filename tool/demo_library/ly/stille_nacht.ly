\version "2.26.0"
\include "common.ily"

\header {
  title = "Stille Nacht, heilige Nacht"
  subtitle = "Text: Joseph Mohr, 1816"
  composer = "Franz Xaver Gruber (1787-1863)"
  tagline = ##f
}

harmonies = \chordmode {
  c2. | c2. | g2. | c2. |
  f2. | c2. | f2. | c2. |
  g2. | c2. | c2. | c2. |
}

melody = {
  \clef treble
  \key c \major
  \time 6/8
  \tempo "Ruhig"

  g'8.\p a'16 g'8 e'4. |
  g'8. a'16 g'8 e'4. |
  d''4 d''8 b'4. |
  c''4 c''8 g'4. |
  a'4 a'8 c''8. b'16 a'8 |
  g'8. a'16 g'8 e'4. |
  a'4 a'8 c''8. b'16 a'8 |
  g'8. a'16 g'8 e'4. |
  d''4 d''8 f''8. d''16 b'8 |
  c''4. e''8 c'' g' |
  e''4. c''8 g' e' |
  g'8. f'16 d'8 c'4.\fermata |
  \bar "|."
}

text = \lyricmode {
  Stil -- le Nacht, hei -- li -- ge Nacht!
  Al -- les schlaeft, ein -- sam wacht
  nur das trau -- te hoch -- hei -- li -- ge Paar.
  Hol -- der Kna -- be im lo -- cki -- gen Haar,
  schlaf in himm -- li -- scher Ruh,
  schlaf in himm -- li -- scher Ruh.
}

\score {
  <<
    \new ChordNames \harmonies
    \new Staff = "melody" \melody
    \addlyrics \text
  >>
  \layout { }
}
