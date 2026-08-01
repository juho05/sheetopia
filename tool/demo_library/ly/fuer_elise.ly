\version "2.26.0"
\include "common.ily"

\header {
  title = "Für Elise"
  subtitle = "Bagatelle a-Moll, WoO 59 (Anfang)"
  composer = "Ludwig van Beethoven (1770-1827)"
  tagline = ##f
}

thema = {
  e''16 dis'' e'' b' d'' c'' |
  a'8 r16 c' e' a' |
  b'8 r16 e' gis' b' |
  c''8 r16 e' e'' dis'' |
  e''16 dis'' e'' b' d'' c'' |
  a'8 r16 c' e' a' |
  b'8 r16 e' c'' b' |
}

themaBass = {
  r4. |
  a,8 e a |
  e,8 e gis |
  a,8 e a |
  r4. |
  a,8 e a |
  e,8 e gis |
}

upper = {
  \clef treble
  \key a \minor
  \time 3/8
  \tempo "Poco moto"

  \partial 8 { e''16\p dis'' }
  \repeat volta 2 {
    \thema
    a'4 r8 |
  }

  \thema
  a'8 a'' gis'' |

  a''16 gis'' a'' e'' g'' f'' |
  e''8 r16 e' g' c'' |
  b'8 r16 e' gis' b' |
  c''8 r16 e' e'' dis'' |

  \thema
  <a' c'' e''>4.\fermata |
  \bar "|."
}

lower = {
  \clef bass
  \key a \minor
  \time 3/8

  \partial 8 { r8 }
  \repeat volta 2 {
    \themaBass
    a,8 e a |
  }

  \themaBass
  a,8 e a |

  a,8 e a |
  c8 g c' |
  e,8 e gis |
  a,8 e a |

  \themaBass
  <a,, a,>4.\fermata |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}