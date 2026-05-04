import SwiftUI

/// A horizontal flow container that inserts a separator view between wrapped child views.
///
/// `HFlowSeparator` lays out the views produced by `content` in a horizontal flow,
/// automatically wrapping them onto new lines when needed. The `separator` view is
/// inserted between adjacent items and hidden when a wrap would leave a separator at
/// the end of a line.
///
/// Example:
/// ```swift
/// HFlowSeparator(spacing: 8) {
///   Text("•")
/// } content: {
///   ForEach(tags, id: \.self) { tag in
///     Text(tag)
///   }
/// }
/// ```
public struct HFlowSeparator<Content: View, Separator: View>: View {
  private let separator: Separator
  private let content: Content

  @State
  private var separatorVisibility: [Int: Bool] = [:]
  private let alignment: HorizontalAlignment
  private let spacing: CGFloat

  public init(
    alignment: HorizontalAlignment = .leading,
    spacing: CGFloat = 0,
    @ViewBuilder separator: () -> Separator,
    @ViewBuilder content: () -> Content
  ) {
    self.alignment = alignment
    self.spacing = spacing
    self.separator = separator()
    self.content = content()
  }

  public var body: some View {
    Group(subviews: content) { subviews in
      let indexedSubviews = Array(zip(subviews.indices, subviews))

      HFlowSeparatorLayout(alignment: alignment, spacing: spacing) {
        ForEach(indexedSubviews, id: \.1.id) { index, subview in
          HStack(spacing: spacing) {
            subview
            
            if index < subviews.index(before: subviews.endIndex) {
              let separatorVisibilityBinding = Binding(
                get: { separatorVisibility[index] ?? false },
                set: { separatorVisibility[index] = $0 }
              )
              
              HStack(spacing: 0) {
                separator
              }
              .opacity(separatorVisibility[index] == true ? 0 : 1)
              .accessibilityHidden(separatorVisibility[index] == true)
              .layoutValue(key: HFlowSeparatorRoleKey.self, value: true)
              .layoutValue(key: HFlowSeparatorVisibilityKey.self, value: separatorVisibilityBinding)
            }
          }
        }
      }
    }
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  let tags = ["Swift", "SwiftUI", "iOS", "Xcode", "Layout", "SPM"]

  HFlowSeparator(alignment: .center, spacing: 8) {
    Image(systemName: "circle.fill")
      .font(.caption2)
      .foregroundStyle(.secondary)
  } content: {
    ForEach(tags, id: \.self) { item in
      Text(item)
    }
  }
}
