\version "2.26.0"
\include "common.ily"

\header {
  title = "Ode an die Freude"
  subtitle = "Symphony No. 9 in D minor, op. 125 - Theme (Trumpet in B-flat)"
  composer = "Ludwig van Beethoven (1770-1827)"
  tagline = ##f
}

trumpet = {
  \clef treble
  \key d \major
  \time 4/4
  \tempo "Allegro assai" 4 = 120

  fis'4\mf fis' g' a' |
  a'4 g' fis' e' |
  d'4 d' e' fis' |
  fis'4. e'8 e'2 |
  fis'4 fis' g' a' |
  a'4 g' fis' e' |
  d'4 d' e' fis' |
  e'4. d'8 d'2 |
  e'4 e' fis' d' |
  e'4 fis'8 g' fis'4 d' |
  e'4 fis'8 g' fis'4 e' |
  d'4 e' a2 |
  fis'4\f fis' g' a' |
  a'4 g' fis' e' |
  d'4 d' e' fis' |
  e'4. d'8 d'2\fermata |
  \bar "|."
}

\score {
  \new Staff \with { instrumentName = "Trumpet in B-flat" } \trumpet
  \layout { }
}

\markup \vspace #1
\markup \wordwrap {
  Sounds a major second lower than written.
}
