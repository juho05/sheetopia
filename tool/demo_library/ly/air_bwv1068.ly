\version "2.26.0"
\include "common.ily"

\header {
  title = "Air"
  subtitle = "Orchestersuite Nr. 3 D-Dur, BWV 1068 - II. Air"
  composer = "Johann Sebastian Bach (1685-1750)"
  tagline = ##f
}

violin = {
  \clef treble
  \key d \major
  \time 4/4
  \tempo "Lento"

  fis''1\p |
  e''2. fis''8 g'' |
  fis''4. e''8 d''4 cis'' |
  d''1 |
  cis''2. d''8 e'' |
  d''4. cis''8 b'4 a' |
  b'2. cis''8 d'' |
  cis''1 |
  a''2. g''8 fis'' |
  g''4. fis''8 e''4 d'' |
  cis''2 d''4. e''8 |
  fis''2. e''8 d'' |
  cis''4. b'8 a'4 g' |
  fis'2 e'4. fis'8 |
  g'4. fis'8 e'4 d' |
  d'1\fermata |
  \bar "|."
}

pianoUpper = {
  \clef treble
  \key d \major
  \time 4/4

  <a' d''>2 <a' cis''> |
  <g' b'>2 <a' cis''> |
  <a' d''>2 <g' b'> |
  <fis' a'>2 <e' a'> |
  <e' a'>2 <fis' a'> |
  <g' b'>2 <fis' a'> |
  <e' g'>2 <e' a'> |
  <e' a'>2 <e' gis'> |
  <a' cis''>2 <b' d''> |
  <b' e''>2 <a' d''> |
  <a' cis''>2 <fis' a'> |
  <a' d''>2 <a' cis''> |
  <g' b'>2 <fis' a'> |
  <d' a'>2 <cis' g'> |
  <b d'>2 <a cis'> |
  <d' fis' a'>1\fermata |
}

pianoLower = {
  \clef bass
  \key d \major
  \time 4/4

  d8 e fis g a b cis' d' |
  b,8 cis d e fis g a b |
  g,8 a, b, cis d e fis g |
  d8 cis d e fis e d cis |
  a,8 b, cis d e fis g a |
  e8 d cis b, a, g, fis, e, |
  cis8 d e fis g fis e d |
  a,8 b, cis d e d cis b, |
  a,8 cis e a cis' e' cis' a |
  g8 fis e d cis b, a, g, |
  fis,8 g, a, b, cis d e fis |
  d8 e fis g a b cis' d' |
  b,8 cis d e fis e d cis |
  d8 cis b, a, g, fis, e, d, |
  g,8 a, b, cis d cis b, a, |
  <d,, d,>1\fermata |
}

\score {
  <<
    \new Staff \with { instrumentName = "Violine" } \violin
    \new PianoStaff \with { instrumentName = "Klavier" } <<
      \new Staff = "upper" \pianoUpper
      \new Staff = "lower" \pianoLower
    >>
  >>
  \layout { }
}
