\version "2.26.0"
\include "common.ily"

\header {
  title = "Chromatic Scale"
  subtitle = "Two octaves, hands together"
  tagline = ##f
}

up = {
  c'16 cis' d' dis' e' f' fis' g' |
  gis' a' ais' b' c'' cis'' d'' dis'' |
  e'' f'' fis'' g'' gis'' a'' ais'' b'' |
  c''' b'' bes'' a'' aes'' g'' ges'' f'' |
  e'' ees'' d'' des'' c'' b' bes' a' |
  aes' g' ges' f' e' ees' d' des' |
  c'2 \bar "|."
}

\score {
  \new PianoStaff <<
    \new Staff {
      \clef treble \key c \major \time 2/4
      \tempo 4 = 100
      \up
    }
    \new Staff {
      \clef bass \key c \major \time 2/4
      \transpose c' c \up
    }
  >>
  \layout { }
}

\markup \vspace #1
\markup \wordwrap {
  Fingering: 3 on every black key, 1 on the others,
  2 between E-F and B-C.
}
