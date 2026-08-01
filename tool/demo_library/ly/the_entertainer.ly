\version "2.26.0"
\include "common.ily"

\header {
  title = "The Entertainer"
  subtitle = "A Rag Time Two Step"
  composer = "Scott Joplin (1868-1917)"
  tagline = ##f
}

upper = {
  \clef treble
  \key c \major
  \time 2/4
  \tempo \markup \italic "Not fast." 4 = 84

  d''16\f e'' c'' a' b' g' d' e' |
  c'16 d' e' c' d' e' c'8 |
  d''16 e'' c'' a' b' g' d' e' |
  c'8 r r4 |

  c''16\mf d'' dis'' e'' c''' e'' c''' e'' |
  c'''8 r16 c'' d'' dis'' e'' c''' |
  e''16 c''' e'' c''' e''8 r |
  r16 a'' g'' fis'' f'' e'' d'' c'' |

  d''16 e'' c'' d'' e''8 r |
  r16 e'' f'' fis'' g'' a'' b'' c''' |
  d'''16 c''' b'' a'' g'' fis'' f'' e'' |
  d''16 c'' d'' e'' c''8 r |

  c''16 d'' dis'' e'' c''' e'' c''' e'' |
  c'''8 r16 c'' d'' dis'' e'' c''' |
  e''16 c''' e'' c''' e''8 r |
  r16 a'' g'' fis'' f'' e'' d'' c'' |

  a'16 c'' e'' a'' g'' e'' c'' a' |
  b'16 d'' g'' b'' a'' g'' d'' b' |
  c''16 e'' g'' c''' b'' g'' e'' c'' |
  <c'' e'' g''>4 r |

  c'''16\f b'' c''' d''' c''' b'' a'' g'' |
  a''16 g'' e'' c'' d''8 r |
  d''16 e'' f'' fis'' g'' a'' b'' c''' |
  d'''8 c''' r4 |

  a''16 g'' fis'' g'' e'' g'' d'' g'' |
  c''16 e'' g'' c''' b'' a'' g'' fis'' |
  g''16 fis'' f'' e'' d'' c'' b' a' |
  g'8 c'' r4 |

  c''16 d'' dis'' e'' c''' e'' c''' e'' |
  c'''8 r16 c'' d'' dis'' e'' c''' |
  e''16 c''' e'' c''' e''8 r |
  r16 a'' g'' fis'' f'' e'' d'' c'' |

  a'16 c'' e'' a'' g'' e'' c'' a' |
  b'16 d'' g'' b'' a'' g'' d'' b' |
  c''16 e'' g'' c''' e''' c''' g'' e'' |
  <c'' e'' g'' c'''>2\fermata |
  \bar "|."
}

lower = {
  \clef bass
  \key c \major
  \time 2/4

  r2 |
  r2 |
  r2 |
  r2 |

  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |

  g,,8 <b, d g> g,,8 <b, d g> |
  g,,8 <b, d g> g,,8 <b, d g> |
  g,,8 <b, d g> g,,8 <b, d g> |
  c,8 <c e g> c,8 <c e g> |

  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |

  a,,8 <a, c e> a,,8 <a, c e> |
  g,,8 <b, d g> g,,8 <b, d g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |

  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  g,,8 <b, d g> g,,8 <b, d g> |
  g,,8 <b, d g> g,,8 <b, d g> |

  d,8 <d fis c'> d,8 <d fis c'> |
  c,8 <c e g> c,8 <c e g> |
  g,,8 <b, d g> g,,8 <b, d g> |
  c,8 <c e g> c,8 <c e g> |

  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |
  c,8 <c e g> c,8 <c e g> |

  a,,8 <a, c e> a,,8 <a, c e> |
  g,,8 <b, d g> g,,8 <b, d g> |
  c,8 <c e g> c,8 <c e g> |
  <c,, c,>2\fermata |
}

\score {
  \new PianoStaff <<
    \new Staff = "upper" \upper
    \new Staff = "lower" \lower
  >>
  \layout { }
}
