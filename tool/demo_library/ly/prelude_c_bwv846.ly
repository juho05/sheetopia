\version "2.26.0"
\include "common.ily"

\header {
  title = "Praeludium I"
  subtitle = "Das Wohltemperierte Klavier I, BWV 846"
  composer = "Johann Sebastian Bach (1685-1750)"
  tagline = ##f
}

% Every bar states a five note broken chord twice: the lower two notes are
% held in the bass staff, the upper three run on in the treble staff.
upper = {
  \clef treble
  \key c \major
  \time 4/4

  \repeat unfold 2 { r8 g'16 c'' e'' g' c'' e'' }
  \repeat unfold 2 { r8 a'16 d'' f'' a' d'' f'' }
  \repeat unfold 2 { r8 g'16 d'' f'' g' d'' f'' }
  \repeat unfold 2 { r8 g'16 c'' e'' g' c'' e'' }
  \break

  \repeat unfold 2 { r8 a'16 e'' a'' a' e'' a'' }
  \repeat unfold 2 { r8 fis'16 a' d'' fis' a' d'' }
  \repeat unfold 2 { r8 g'16 d'' g'' g' d'' g'' }
  \repeat unfold 2 { r8 e'16 g' c'' e' g' c'' }
  \break

  \repeat unfold 2 { r8 e'16 g' c'' e' g' c'' }
  \repeat unfold 2 { r8 d'16 fis' c'' d' fis' c'' }
  \repeat unfold 2 { r8 d'16 g' b' d' g' b' }
  \repeat unfold 2 { r8 e'16 g' cis'' e' g' cis'' }
  \break

  \repeat unfold 2 { r8 d'16 a' d'' d' a' d'' }
  \repeat unfold 2 { r8 d'16 f' b' d' f' b' }
  \repeat unfold 2 { r8 c'16 g' c'' c' g' c'' }
  \repeat unfold 2 { r8 c'16 a' c'' c' a' c'' }
  \break

  \repeat unfold 2 { r8 a16 f' c'' a f' c'' }
  \repeat unfold 2 { r8 g16 f' b' g f' b' }
  \repeat unfold 2 { r8 g16 e' c'' g e' c'' }
  \repeat unfold 2 { r8 g16 d' c'' g d' c'' }
  \break

  \repeat unfold 2 { r8 g16 d' b' g d' b' }
  \repeat unfold 2 { r8 g16 ees' bes' g ees' bes' }
  \repeat unfold 2 { r8 f16 d' aes' f d' aes' }
  \repeat unfold 2 { r8 g16 d' g' g d' g' }
  \break

  \repeat unfold 2 { r8 g16 c' e' g c' e' }
  \repeat unfold 2 { r8 f16 c' f' f c' f' }
  \repeat unfold 2 { r8 f16 b c' f b c' }
  <c' e' g' c''>1\fermata
  \bar "|."
}

lower = {
  \clef bass
  \key c \major
  \time 4/4

  \repeat unfold 2 { c8 e r4 }
  \repeat unfold 2 { c8 d r4 }
  \repeat unfold 2 { b,8 d r4 }
  \repeat unfold 2 { c8 e r4 }

  \repeat unfold 2 { c8 e r4 }
  \repeat unfold 2 { c8 d r4 }
  \repeat unfold 2 { b,8 d r4 }
  \repeat unfold 2 { c8 e r4 }

  \repeat unfold 2 { a,8 e r4 }
  \repeat unfold 2 { a,8 d r4 }
  \repeat unfold 2 { g,8 d r4 }
  \repeat unfold 2 { g,8 bes r4 }

  \repeat unfold 2 { fis,8 a r4 }
  \repeat unfold 2 { aes,8 f r4 }
  \repeat unfold 2 { g,8 e r4 }
  \repeat unfold 2 { g,8 f r4 }

  \repeat unfold 2 { f,8 f r4 }
  \repeat unfold 2 { g,8 d r4 }
  \repeat unfold 2 { c,8 e r4 }
  \repeat unfold 2 { c,8 f r4 }

  \repeat unfold 2 { c,8 f r4 }
  \repeat unfold 2 { c,8 g r4 }
  \repeat unfold 2 { c,8 aes r4 }
  \repeat unfold 2 { c,8 g r4 }

  \repeat unfold 2 { c,8 g r4 }
  \repeat unfold 2 { c,8 aes r4 }
  \repeat unfold 2 { c,8 g r4 }
  <c,, c,>1\fermata
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}