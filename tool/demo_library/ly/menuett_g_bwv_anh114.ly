\version "2.26.0"
\include "common.ily"

\header {
  title = "Menuett in G"
  subtitle = "Notenbüchlein für Anna Magdalena Bach, BWV Anh. 114"
  composer = "Christian Petzold (1677-1733)"
  tagline = ##f
}

upper = {
  \clef treble
  \key g \major
  \time 3/4

  \repeat volta 2 {
    d''4 g'8 a' b' c'' |
    d''4 g'4 g' |
    e''4 c''8 d'' e'' fis'' |
    g''4 g'4 g' |
    c''4 d''8 c'' b' a' |
    b'4 c''8 b' a' g' |
    a'4 b'8 a' g' fis' |
    g'2. |
  }

  \repeat volta 2 {
    b'4 g'8 a' b' g' |
    a'4 d'8 e' fis' d' |
    g'4 e'8 fis' g' d' |
    cis''4 b'8 cis'' a'4 |
    a'4 fis'8 g' a' fis' |
    g'4 e'8 fis' g' e' |
    a'4 b'8 a' g' fis' |
    g'2. |
  }
}

lower = {
  \clef bass
  \key g \major
  \time 3/4

  \repeat volta 2 {
    g2 a4 |
    b2 g4 |
    c'2 b4 |
    a2 g4 |
    fis2 g4 |
    g2 d4 |
    d2 d,4 |
    g,2. |
  }

  \repeat volta 2 {
    g2 fis4 |
    e2 d4 |
    b,2 c4 |
    a,2 a,4 |
    d2 c4 |
    b,2 a,4 |
    d2 d,4 |
    g,2. |
  }
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
  \header { piece = \markup \italic "Moderato" }
}