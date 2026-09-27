\version "2.26.0"
\include "common.ily"

\header {
  title = "Amazing Grace"
  subtitle = "Tune: New Britain / Words: John Newton, 1779"
  composer = "Traditional"
  tagline = ##f
}

harmonies = \chordmode {
  \partial 4 s4
  g2. | g2. | c2. | g2. |
  g2. | e2.:m | d2. | d2. |
  g2. | c2. | g2. | e2.:m |
  g2. | c2. | g2. | g2. |
}

melody = {
  \clef treble
  \key g \major
  \time 3/4
  \tempo "Slowly, with feeling"

  \partial 4 d'4 |
  g'2 b'8 g' |
  b'2 a'4 |
  g'2 e'4 |
  d'2 d'4 |

  g'2 b'8 g' |
  b'2 a'4 |
  d''2. |
  d''2 d''4 |

  b'2 d''8 b' |
  d''2 b'4 |
  g'2 e'4 |
  d'2 d'4 |

  g'2 b'8 g' |
  b'2 a'4 |
  g'2 e'4 |
  g'2.\fermata |
  \bar "|."
}

text = \lyricmode {
  A -- ma -- zing grace, how sweet the sound
  that saved a wretch like me.
  I once was lost, but now am found,
  was blind, but now I see.
}

\score {
  <<
    \new ChordNames \harmonies
    \new Staff = "melody" \melody
    \addlyrics \text
  >>
  \layout { }
}