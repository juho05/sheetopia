\version "2.26.0"
\include "common.ily"

\header {
  title = "Ah vous dirai-je, maman"
  subtitle = "Thema, nach KV 265"
  composer = "Wolfgang Amadeus Mozart (1756-1791)"
  tagline = ##f
}

flute = {
  \clef treble
  \key c \major
  \time 2/4
  \tempo "Allegretto"

  c''4\p c'' | g'' g'' | a'' a'' | g''2 |
  f''4 f'' | e'' e'' | d'' d'' | c''2 |
  g''4 g'' | f'' f'' | e'' e'' | d''2 |
  g''4 g'' | f'' f'' | e'' e'' | d''2 |
  c''4 c'' | g'' g'' | a'' a'' | g''2 |
  f''4 f'' | e'' e'' | d'' d'' | c''2\fermata |
  \bar "|."
}

pianoUpper = {
  \clef treble
  \key c \major
  \time 2/4

  <c' e'>4 <c' e'> | <b d'> <b d'> | <c' f'> <c' f'> | <b d'>2 |
  <a c'>4 <a c'> | <g c'> <g c'> | <f b> <f b> | <e g>2 |
  <b d'>4 <b d'> | <a c'> <a c'> | <g c'> <g c'> | <f b>2 |
  <b d'>4 <b d'> | <a c'> <a c'> | <g c'> <g c'> | <f b>2 |
  <c' e'>4 <c' e'> | <b d'> <b d'> | <c' f'> <c' f'> | <b d'>2 |
  <a c'>4 <a c'> | <g c'> <g c'> | <f b> <f b> | <e g>2\fermata |
}

pianoLower = {
  \clef bass
  \key c \major
  \time 2/4

  c4 c | g, g, | f f | g, g, |
  f4 f | c c | g, g, | c2 |
  g,4 g, | f f | c c | g, g, |
  g,4 g, | f f | c c | g, g, |
  c4 c | g, g, | f f | g, g, |
  f4 f | c c | g, g, | c2\fermata |
}

\score {
  <<
    \new Staff \with { instrumentName = "Flute" } \flute
    \new PianoStaff \with { instrumentName = "Piano" } <<
      \new Staff = "upper" \pianoUpper
      \new Staff = "lower" \pianoLower
    >>
  >>
  \layout { }
}