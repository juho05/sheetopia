\version "2.26.0"
\include "common.ily"

\header {
  title = "Canon in D"
  subtitle = "Canon and Gigue in D major, P 37"
  composer = "Johann Pachelbel (1653-1706)"
  tagline = ##f
}

violin = {
  \clef treble
  \key d \major
  \time 4/4
  \tempo "Andante"

  R1 | R1 |
  fis''2\p e'' |
  d''2 cis'' |
  b'2 a' |
  b'2 cis'' |
  d''2 cis'' |
  b'2 a' |
  g'2 fis' |
  g'2 e' |
  d''8\mf fis'' a'' g'' fis'' d'' fis'' e'' |
  d''8 b' d'' a' g' b' a' g' |
  fis'8 d' e' fis' g' a' b' cis'' |
  d''8 e'' fis'' g'' a'' b'' a'' g'' |
  fis''8 d'' e'' fis'' g'' fis'' e'' d'' |
  cis''8 b' a' b' cis'' d'' e'' fis'' |
  d''1\fermata |
  \bar "|."
}

cello = {
  \clef bass
  \key d \major
  \time 4/4

  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  d4 a, b, fis, |
  g,4 d, g, a, |
  <d, d>1\fermata |
}

\score {
  \new StaffGroup <<
    \new Staff \with { instrumentName = "Violin" } \violin
    \new Staff \with { instrumentName = "Cello" } \cello
  >>
  \layout { }
}
