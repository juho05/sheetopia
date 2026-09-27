\version "2.26.0"
\include "common.ily"

\header {
  title = "Open Strings"
  subtitle = "Long bows and string crossings"
  tagline = ##f
}

\score {
  \new Staff {
    \clef treble \key c \major \time 4/4
    \tempo "Slowly" 4 = 60
    \mark "Whole bows"
    g1\downbow | g1\upbow | d'1\downbow | d'1\upbow |
    a'1\downbow | a'1\upbow | e''1\downbow | e''1\upbow \bar "||"
    \break
    \mark "Detache"
    g4\downbow g\upbow g g | d'\downbow d'\upbow d' d' |
    a'\downbow a'\upbow a' a' | e''\downbow e''\upbow e'' e'' |
    e''\downbow e''\upbow e'' e'' | a'\downbow a'\upbow a' a' |
    d'\downbow d'\upbow d' d' | g\downbow g\upbow g g \bar "||"
    \break
    \mark "String crossings"
    g8\downbow d' g d' g d' g d' | d' a' d' a' d' a' d' a' |
    a' e'' a' e'' a' e'' a' e'' | a' e'' a' e'' a' e'' a' e'' |
    d' a' d' a' d' a' d' a' | g d' g d' g d' g d' |
    g1\fermata \bar "|."
  }
  \layout { }
}

\markup \vspace #1
\markup \wordwrap {
  Keep the bow straight between fingerboard and bridge. Even sound from frog to tip.
}
