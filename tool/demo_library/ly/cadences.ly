\version "2.26.0"
\include "common.ily"

\header {
  title = "Cadences"
  subtitle = "I - IV - V7 - I in six keys"
  tagline = ##f
}

upper = { <e' g' c''>2 <f' a' c''> | <f' g' b'> <e' g' c''> \bar "||" }
lower = { c2 f, | g, c \bar "||" }
numerals = \lyricmode { I2 IV "V7" I }

inKey = #(define-music-function (name key music) (markup? ly:pitch? ly:music?)
  #{ \sectionLabel $name \transpose c $key { \key c \major $music } #})

rightHand = {
  \inKey "C major" c \upper
  \inKey "G major" g, \upper \break
  \inKey "D major" d \upper
  \inKey "A major" a, \upper \break
  \inKey "F major" f, \upper
  \inKey "B-flat major" bes, \upper
}

leftHand = {
  \transpose c c { \key c \major \lower }
  \transpose c g, { \key c \major \lower }
  \transpose c d { \key c \major \lower }
  \transpose c a, { \key c \major \lower }
  \transpose c f, { \key c \major \lower }
  \transpose c bes, { \key c \major \lower }
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" { \clef treble \time 4/4 \rightHand }
    \new Staff = "lower" { \clef bass \time 4/4 \leftHand }
    \new Lyrics { \numerals \numerals \numerals \numerals \numerals \numerals }
  >>
  \layout { ragged-right = ##f ragged-last = ##f }
}

\markup \vspace #1
\markup \wordwrap {
  Slow and legato. Watch the voice leading and hold common tones.
}
