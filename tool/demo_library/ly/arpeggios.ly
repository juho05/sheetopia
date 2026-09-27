\version "2.26.0"
\include "common.ily"

\header {
  title = "Arpeggios"
  subtitle = "Major triads over two octaves"
  tagline = ##f
}

arpUp = {
  c'16 e' g' c'' e'' g'' c''' g'' |
  e'' c'' g' e' c'4 \bar "||"
}

arpUpFingered = {
  c'16-1 e'-2 g'-3 c''-1 e''-2 g''-3 c'''-5 g''-3 |
  e''-2 c''-1 g'-3 e'-2 c'4-1 \bar "||"
}

arpDownFingered = {
  c16-5 e-4 g-2 c'-1 e'-4 g'-2 c''-1 g'-2 |
  e'-4 c'-1 g-2 e-4 c4-5 \bar "||"
}

arpDown = \transpose c' c \arpUp

arpPair = #(define-music-function (key upper lower) (ly:pitch? ly:music? ly:music?)
  #{
    \new PianoStaff <<
      \new Staff { \clef treble \key $key \major \time 2/4 $upper }
      \new Staff { \clef bass \key $key \major \time 2/4 $lower }
    >>
  #})

\score {
  \header { piece = "C major" }
  \arpPair c \arpUpFingered \arpDownFingered
  \layout { ragged-right = ##f }
}

\score {
  \header { piece = "G major" }
  \arpPair g \transpose c g, \arpUp \transpose c g, \arpDown
  \layout { ragged-right = ##f }
}

\score {
  \header { piece = "F major" }
  \arpPair f \transpose c f, \arpUp \transpose c f, \arpDown
  \layout { ragged-right = ##f }
}

\score {
  \header { piece = "D major" }
  \arpPair d \transpose c d \arpUp \transpose c d \arpDown
  \layout { ragged-right = ##f }
}
