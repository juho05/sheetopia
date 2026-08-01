\version "2.26.0"
\include "common.ily"

\header {
  title = "Solfeggietto"
  subtitle = "c-Moll, H 220 (Anfang)"
  composer = "Carl Philipp Emanuel Bach (1714-1788)"
  tagline = ##f
}

upper = {
  \clef treble
  \key c \minor
  \time 2/4
  \tempo "Prestissimo"

  c''16 ees'' g'' c''' ees''' c''' g'' ees'' |
  r8 r16 c''' aes'' f'' d'' b' |
  c'' ees'' g'' c''' ees''' c''' g'' ees'' |
  r8 r16 aes'' f'' d'' b' g' |
  c'' ees'' g'' c''' ees''' c''' g'' ees'' |
  d'' f'' aes'' d''' f''' d''' aes'' f'' |
  ees'' g'' c''' ees''' g''' ees''' c''' g'' |
  r8 r16 f''' d''' b'' g'' ees'' |
  c'' ees'' g'' c''' ees''' c''' g'' ees'' |
  r8 r16 c''' aes'' f'' d'' b' |
  c'' ees'' g'' c''' g'' ees'' c'' g' |
  <c'' ees'' g''>2\fermata |
  \bar "|."
}

lower = {
  \clef bass
  \key c \minor
  \time 2/4

  r2 |
  c16 ees g c' ees' c' g ees |
  r2 |
  c16 ees g c' ees' c' g ees |
  r2 |
  r2 |
  r2 |
  c16 ees g c' ees' c' g ees |
  r2 |
  c16 ees g c' ees' c' g ees |
  r2 |
  <c, c>2\fermata |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}
