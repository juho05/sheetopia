\version "2.26.0"
\include "common.ily"

\header {
  title = "Minor Scales"
  subtitle = "Harmonic, two octaves, hands together"
  tagline = ##f
}

scaleUp = {
  a16 b c' d' e' f' gis' a' |
  b' c'' d'' e'' f'' gis'' a'' gis'' |
  f'' e'' d'' c'' b' a' gis' f' |
  e' d' c' b a4 \bar "||"
}

scaleDown = \transpose c' c \scaleUp

scalePair = #(define-music-function (key upper lower) (ly:pitch? ly:music? ly:music?)
  #{
    \new PianoStaff <<
      \new Staff { \clef treble \key $key \minor \time 2/4 $upper }
      \new Staff { \clef bass \key $key \minor \time 2/4 $lower }
    >>
  #})

\score {
  \header { piece = "A minor" }
  \scalePair a \scaleUp \scaleDown
  \layout { }
}

\score {
  \header { piece = "E minor" }
  \scalePair e \transpose a e' \scaleUp \transpose a e' \scaleDown
  \layout { }
}

\score {
  \header { piece = "D minor" }
  \scalePair d \transpose a d' \scaleUp \transpose a d' \scaleDown
  \layout { }
}
