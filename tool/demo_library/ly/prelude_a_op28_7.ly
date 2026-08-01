\version "2.26.0"
\include "common.ily"

\header {
  title = "Prélude in A"
  subtitle = "24 Préludes, op. 28 Nr. 7"
  composer = "Frédéric Chopin (1810-1849)"
  tagline = ##f
}

upper = {
  \clef treble
  \key a \major
  \time 3/4
  \tempo "Andantino"

  \partial 8 cis''8\p |
  e''4. cis''8 e''4 |
  fis''4. e''8 cis''4 |
  b'4. cis''8 d''4 |
  cis''2 r8 e''8 |
  \break
  gis''4. e''8 gis''4 |
  a''4. gis''8 e''4 |
  d''4. e''8 fis''4 |
  e''2 r8 cis''8 |
  \break
  e''4. cis''8 e''4 |
  fis''4. e''8 cis''4 |
  b'4. cis''8 d''4 |
  <b' d'' fis'' a''>2.\f |
  \break
  gis''4.\p e''8 gis''4 |
  a''4. gis''8 e''4 |
  d''4. cis''8 b'4 |
  <a' cis'' e''>2.\fermata |
  \bar "|."
}

lower = {
  \clef bass
  \key a \major
  \time 3/4

  \partial 8 r8 |
  a,4 <e a cis'> <e a cis'> |
  a,4 <e a cis'> <e a cis'> |
  e,4 <e gis d'> <e gis d'> |
  a,4 <e a cis'> <e a cis'> |
  e,4 <e gis b> <e gis b> |
  a,4 <e a cis'> <e a cis'> |
  b,4 <dis a b> <dis a b> |
  e,4 <e gis b> <e gis b> |
  a,4 <e a cis'> <e a cis'> |
  a,4 <e a cis'> <e a cis'> |
  e,4 <e gis d'> <e gis d'> |
  b,4 <dis fis a> <dis fis a> |
  e,4 <e gis b> <e gis b> |
  a,4 <e a cis'> <e a cis'> |
  e,4 <e gis b> <e gis b> |
  <a,, a,>2.\fermata |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}
