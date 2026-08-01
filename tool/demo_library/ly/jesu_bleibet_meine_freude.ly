\version "2.26.0"
\include "common.ily"

\header {
  title = "Jesu, bleibet meine Freude"
  subtitle = "Kantate BWV 147, Choralsatz"
  composer = "Johann Sebastian Bach (1685-1750)"
  tagline = ##f
}

upper = {
  \clef treble
  \key g \major
  \time 9/8
  \tempo "Andante"

  g'8 a' b' d'' c'' b' g' b' a' |
  g' fis' g' a' d'' c'' b' a' g' |
  a' b' c'' d'' e'' d'' c'' b' a' |
  b' g' a' b' c'' b' a' g' fis' |
  g' a' b' d'' c'' b' g' b' a' |
  g' fis' g' a' d'' c'' b' a' g' |
  fis' g' a' b' a' g' fis' e' d' |
  e' fis' g' a' g' fis' e' d' cis' |
  d' e' fis' g' a' b' c'' b' a' |
  b' g' a' b' c'' b' a' g' fis' |
  g'2.~ g'4.\fermata |
  \bar "|."
}

lower = {
  \clef bass
  \key g \major
  \time 9/8

  g4. b, d |
  g,4. d g, |
  a,4. c e |
  d4. g, d |
  g,4. b, d |
  g,4. d g, |
  d4. c b, |
  a,4. d, a, |
  d4. g, d |
  g,4. d d, |
  <g,, g,>2.~ <g,, g,>4.\fermata |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}
