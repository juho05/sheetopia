\version "2.26.0"
\include "common.ily"

\header {
  title = "Scarborough Fair"
  subtitle = "English ballad, traditional"
  composer = "Traditional"
  tagline = ##f
}

harmonies = \chordmode {
  \partial 4 s4
  a2.:m | c2. | a2.:m | a2.:m |
  a2.:m | g2. | a2.:m | a2.:m |
  a2.:m | c2. | g2. | a2.:m |
  a2.:m | c2. | g2. | a2.:m |
  a2.:m | g2. | a2.:m | a2.:m |
}

melody = {
  \clef treble
  \key a \minor
  \time 3/4
  \tempo "Flowing"

  \partial 4 a'4 |
  a'2 e''4 | e''2 e''4 | b'4. c''8 d''4 | b'2 a'4 |
  a'2 c''4 | b'2 a'4 | g'2 e'4 | a'2 a'4 |
  a'2 c''4 | d''2 e''4 | e''2 e''4 | d''2 c''4 |
  b'2 g'4 | a'2 c''4 | b'2 a'4 | a'2 e''4 |
  e''2 d''4 | c''2 b'4 | a'4. g'8 e'4 | a'2.\fermata |
  \bar "|."
}

text = \lyricmode {
  Are you go -- ing to Scar -- bo -- rough Fair?
  Pars -- ley, sage, rose -- ma -- ry and thyme.
  Re -- mem -- ber me to one who lives there,
  she once was a true love of mine.
}

\score {
  <<
    \new ChordNames \harmonies
    \new Staff = "melody" \melody
    \addlyrics \text
  >>
  \layout { }
}
