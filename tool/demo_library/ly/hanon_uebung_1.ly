\version "2.26.0"
\include "common.ily"

\header {
  title = "Übung Nr. 1"
  subtitle = "Der Klaviervirtuose, Teil I"
  composer = "Charles-Louis Hanon (1819-1900)"
  tagline = ##f
}

upperUp = {
  c'16 e' f' g' a' g' f' e' |
  d' f' g' a' b' a' g' f' |
  e' g' a' b' c'' b' a' g' |
  f' a' b' c'' d'' c'' b' a' |
  g' b' c'' d'' e'' d'' c'' b' |
  a' c'' d'' e'' f'' e'' d'' c'' |
  b' d'' e'' f'' g'' f'' e'' d'' |
  c'' e'' f'' g'' a'' g'' f'' e'' |
}

upperDown = {
  d'' b' a' g' f' g' a' b' |
  c'' a' g' f' e' f' g' a' |
  b' g' f' e' d' e' f' g' |
  a' f' e' d' c' d' e' f' |
  g' e' d' c' b e' d' c' |
  a4 r |
}

lowerUp = {
  c16 e f g a g f e |
  d f g a b a g f |
  e g a b c' b a g |
  f a b c' d' c' b a |
  g b c' d' e' d' c' b |
  a c' d' e' f' e' d' c' |
  b d' e' f' g' f' e' d' |
  c' e' f' g' a' g' f' e' |
}

lowerDown = {
  d' b a g f g a b |
  c' a g f e f g a |
  b g f e d e f g |
  a f e d c d e f |
  g e d c b, e d c |
  a,4 r |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" {
      \clef treble
      \key c \major
      \time 2/4
      \tempo "Allegro" 4 = 108
      \upperUp
      \upperDown
      \bar "|."
    }
    \new Staff = "lower" {
      \clef bass
      \key c \major
      \time 2/4
      \lowerUp
      \lowerDown
    }
  >>
  \layout { }
}

\markup \vspace #1
\markup \wordwrap {
  Jeden Takt gleichmäßig und mit festem Anschlag üben.
  Zuerst langsam, dann allmählich schneller bis zum angegebenen Tempo.
}