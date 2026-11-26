import SwiftUI

/// Changes stack geometry while keeping one stable tree of stateful controls.
/// Accessibility callers can require a column without replacing the content.
struct StudioAdaptiveLayout: Layout {
    var forceVertical: Bool = false
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let proposal = normalized(proposal)
        let layout = stack(for: proposal, subviews: subviews)
        var stackCache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &stackCache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let proposal = normalized(proposal)
        let layout = stack(for: proposal, subviews: subviews)
        var stackCache = layout.makeCache(subviews: subviews)
        // Prepare this stack's cache using the same proposal that chose its
        // axis. An unrelated earlier sizing probe must not choose placement.
        _ = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &stackCache)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &stackCache)
    }

    private func stack(for proposal: ProposedViewSize, subviews: Subviews) -> AnyLayout {
        let spacing = spacing.isFinite ? max(0, spacing) : 0
        let vertical = AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        guard !forceVertical else { return vertical }

        let horizontal = AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
        // An unspecified or infinite width asks for ideal size. A finite
        // width must fit the complete row before it can use that geometry.
        guard let availableWidth = proposal.width else { return horizontal }
        var idealCache = horizontal.makeCache(subviews: subviews)
        let idealWidth = horizontal.sizeThatFits(proposal: .unspecified,
                                                subviews: subviews, cache: &idealCache).width
        return idealWidth.isFinite && idealWidth <= availableWidth ? horizontal : vertical
    }

    private func normalized(_ proposal: ProposedViewSize) -> ProposedViewSize {
        ProposedViewSize(width: finiteDimension(proposal.width),
                         height: finiteDimension(proposal.height))
    }

    private func finiteDimension(_ value: CGFloat?) -> CGFloat? {
        guard let value, value.isFinite else { return nil }
        return max(0, value)
    }
}
