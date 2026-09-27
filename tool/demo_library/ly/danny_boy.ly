\version "2.26.0"
\include "common.ily"

\header {
  title = "Danny Boy"
  subtitle = "Londonderry Air, Irish traditional"
  composer = "Traditional"
  tagline = ##f
}

harmonies = \chordmode {
  \partial 4 s4
  f1 | f1 | bes1 | f1 |
  f1 | c1 | f1 | c1 |
  f1 | f1 | bes1 | f1 |
  d1:m | c1 | f1 | f1 |
}

melody = {
  \clef treble
  \key f \major
  \time 4/4
  \tempo "Slowly, with expression"

  \partial 4 c'4 |
  f'2 g'4 a' |
  a'4. g'8 f'4 a' |
  c''2. bes'4 |
  a'2. f'4 |
  g'2 a'4 g' |
  f'4. e'8 d'4 c' |
  f'2. f'4 |
  g'2. a'4 |
  bes'2 a'4 g' |
  a'4. g'8 f'4 a' |
  c''2. d''4 |
  c''2. a'4 |
  d''2 c''4 bes' |
  a'4. g'8 f'4 e' |
  f'2. f'4 |
  f'1\fermata |
  \bar "|."
}

text = \lyricmode {
  Oh, Dan -- ny Boy, the pipes, the pipes are call -- ing
  from glen to glen, and down the moun -- tain side.
  The sum -- mer's gone, and all the flow'rs are dy -- ing,
  'tis you, 'tis you must go and I must bide.
}

\score {
  <<
    \new ChordNames \harmonies
    \new Staff = "melody" \melody
    \addlyrics \text
  >>
  \layout { }
}
