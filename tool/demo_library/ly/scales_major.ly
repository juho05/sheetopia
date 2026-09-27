\version "2.26.0"
\include "common.ily"

\header {
  title = "Major Scales"
  subtitle = "Two octaves, hands together"
  tagline = ##f
}

scaleUp = {
  c'16 d' e' f' g' a' b' c'' |
  d'' e'' f'' g'' a'' b'' c''' b'' |
  a'' g'' f'' e'' d'' c'' b' a' |
  g' f' e' d' c'4 \bar "||"
}

scaleUpFingered = {
  c'16-1 d'-2 e'-3 f'-1 g'-2 a'-3 b'-4 c''-1 |
  d''-2 e''-3 f''-1 g''-2 a''-3 b''-4 c'''-5 b''-4 |
  a''-3 g''-2 f''-1 e''-3 d''-2 c''-1 b'-4 a'-3 |
  g'-2 f'-1 e'-3 d'-2 c'4-1 \bar "||"
}

scaleDownFingered = {
  c16-5 d-4 e-3 f-2 g-1 a-3 b-2 c'-1 |
  d'-4 e'-3 f'-2 g'-1 a'-3 b'-2 c''-1 b'-2 |
  a'-3 g'-1 f'-2 e'-3 d'-4 c'-1 b-2 a-3 |
  g-1 f-2 e-3 d-4 c4-5 \bar "||"
}

scaleDown = \transpose c' c \scaleUp

scalePair = #(define-music-function (key upper lower) (ly:pitch? ly:music? ly:music?)
  #{
    \new PianoStaff <<
      \new Staff { \clef treble \key $key \major \time 2/4 $upper }
      \new Staff { \clef bass \key $key \major \time 2/4 $lower }
    >>
  #})

\score {
  \header { piece = "C major" }
  \scalePair c \scaleUpFingered \scaleDownFingered
  \layout { }
}

\score {
  \header { piece = "G major" }
  \scalePair g \transpose c g, \scaleUp \transpose c g, \scaleDown
  \layout { }
}

\score {
  \header { piece = "D major" }
  \scalePair d \transpose c d \scaleUp \transpose c d \scaleDown
  \layout { }
}

\score {
  \header { piece = "F major" }
  \scalePair f \transpose c f, \scaleUp \transpose c f, \scaleDown
  \layout { }
}

\markup \vspace #1
\markup \wordwrap {
  Each hand alone first, then together. Pass the thumb under without turning the wrist.
}
