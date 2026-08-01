\version "2.26.0"
\include "common.ily"

\header {
  title = "Romanza"
  subtitle = "Spanische Romanze für Gitarre"
  composer = "Anonymus (19. Jahrhundert)"
  tagline = ##f
}

guitar = {
  \key e \minor
  \time 3/4
  \tempo "Andante"

  \tuplet 3/2 { e''8 b' e' } \tuplet 3/2 { e''8 b' e' } \tuplet 3/2 { e''8 b' e' } |
  \tuplet 3/2 { d''8 b' e' } \tuplet 3/2 { d''8 b' e' } \tuplet 3/2 { d''8 b' e' } |
  \tuplet 3/2 { c''8 b' e' } \tuplet 3/2 { c''8 b' e' } \tuplet 3/2 { c''8 b' e' } |
  \tuplet 3/2 { b'8 g' e' } \tuplet 3/2 { b'8 g' e' } \tuplet 3/2 { b'8 g' e' } |
  \tuplet 3/2 { b'8 fis' dis' } \tuplet 3/2 { b'8 fis' dis' } \tuplet 3/2 { b'8 fis' dis' } |
  \tuplet 3/2 { a'8 fis' dis' } \tuplet 3/2 { a'8 fis' dis' } \tuplet 3/2 { a'8 fis' dis' } |
  \tuplet 3/2 { g'8 fis' dis' } \tuplet 3/2 { g'8 fis' dis' } \tuplet 3/2 { g'8 fis' dis' } |
  \tuplet 3/2 { fis'8 dis' b } \tuplet 3/2 { fis'8 dis' b } \tuplet 3/2 { fis'8 dis' b } |
  \tuplet 3/2 { e''8 b' e' } \tuplet 3/2 { e''8 b' e' } \tuplet 3/2 { e''8 b' e' } |
  \tuplet 3/2 { g''8 b' e' } \tuplet 3/2 { g''8 b' e' } \tuplet 3/2 { g''8 b' e' } |
  \tuplet 3/2 { fis''8 a' d' } \tuplet 3/2 { fis''8 a' d' } \tuplet 3/2 { fis''8 a' d' } |
  \tuplet 3/2 { e''8 b' g' } \tuplet 3/2 { e''8 b' g' } \tuplet 3/2 { e''8 b' g' } |
  \tuplet 3/2 { d''8 a' fis' } \tuplet 3/2 { d''8 a' fis' } \tuplet 3/2 { d''8 a' fis' } |
  \tuplet 3/2 { b'8 g' e' } \tuplet 3/2 { b'8 g' e' } \tuplet 3/2 { b'8 g' e' } |
  \tuplet 3/2 { b'8 fis' dis' } \tuplet 3/2 { b'8 fis' dis' } \tuplet 3/2 { b'8 fis' dis' } |
  \tuplet 3/2 { e''8 b' e' } \tuplet 3/2 { e''8 b' e' } <e' b' e''>4\fermata |
  \bar "|."
}

\score {
  \new StaffGroup <<
    \new Staff \with { instrumentName = "Gitarre" } {
      \clef "treble_8"
      \guitar
    }
    \new TabStaff \with { stringTunings = #guitar-tuning } {
      \guitar
    }
  >>
  \layout { }
}
