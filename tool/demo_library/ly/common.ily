\version "2.26.0"

#(set-global-staff-size 20)

\paper {
  #(set-paper-size "a4")
  top-margin = 14\mm
  bottom-margin = 14\mm
  left-margin = 16\mm
  right-margin = 16\mm
  markup-system-spacing.padding = #4
  ragged-last-bottom = ##t
  print-page-number = ##t
  oddHeaderMarkup = ##f
  evenHeaderMarkup = ##f
}

\layout {
  \context {
    \Score
    \override BarNumber.break-visibility = #end-of-line-invisible
  }
}