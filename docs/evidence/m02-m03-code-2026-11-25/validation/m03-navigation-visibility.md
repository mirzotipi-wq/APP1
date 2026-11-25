# M03 navigation visibility correction

Independent a056 review found that a presented precision editor retains both the underlying studio navigation bar and its own navigation bar in the accessibility tree. The recorded actual sheet snapshot places their lower edges at116pt and132pt respectively. Selecting the first bar can accept a text frame beginning at124pt even though the presented bar covers it.

Both the scrolling helper and the separate actual-container containment check now account for the maximum lower edge of every finite, nonempty navigation-bar frame overlapping the current content viewport. The helper retains its8pt margin; the independent check uses the actual boundary. Neither visibility nor the44pt control minimum is relaxed. Fixed controls remain checked directly.

For full-frame navigation only, the helper's initial screen inset is now8pt rather than the old100pt midpoint-navigation margin. Observed navigation bars, keyboard and edit controls still bound it; the separate assertion still requires containment in the actual scroll surface. This avoids demanding that the final Form footer scroll100pt above the screen bottom after reaching the Form's natural end. This was a source-derived false-failure risk, not an observed native AXXXL result. Ordinary functional midpoint navigation is unchanged.

The two changed Swift files parsed with Swift6.2.1. Shard inventory remains117 native methods and35 required UI methods, plus2 opt-in audits. Diff validation passed. This is a correction to the assertion's geometry, not a claim of Apple execution or a currently observed product clipping defect. The first candidate's CI is superseded by the next source revision; only finalized outcomes at the tested source count toward acceptance.
