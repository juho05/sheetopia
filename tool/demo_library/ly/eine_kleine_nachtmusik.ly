\version "2.26.0"
\include "common.ily"

\header {
  title = "Eine kleine Nachtmusik"
  subtitle = "Serenade G-Dur, KV 525 - I. Allegro (Violine I)"
  composer = "Wolfgang Amadeus Mozart (1756-1791)"
  tagline = ##f
}

violin = {
  \clef treble
  \key g \major
  \time 4/4
  \tempo "Allegro"

  g'4\f d' g'8 d' g' b' |
  d''4 r r2 |
  c''4 a' fis'8 a' c'' a' |
  d''4 r r2 |
  d''8\p g' g' g' g' g' g' g' |
  d''8 b' b' b' b' b' b' b' |
  d''8 c'' c'' c'' c'' c'' c'' c'' |
  d''8 a' a' a' a' a' a' a' |
  g'8 b' d'' g'' fis'' d'' c'' a' |
  b'8 g' a' fis' g'4 r |
  d''8\f e'' fis'' g'' a'' b'' c''' a'' |
  b''4 g'' d''2 |
  c'''8 b'' a'' g'' fis'' e'' d'' c'' |
  b'8 a' g' fis' g'4 r |
  d''8 g'' fis'' e'' d'' c'' b' a' |
  g'2 g'\fermata |
  \bar "|."
}

\score {
  \new Staff \with { instrumentName = "Violine I" } \violin
  \layout { }
}
