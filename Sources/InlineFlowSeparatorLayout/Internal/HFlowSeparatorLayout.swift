import SwiftUI

struct HFlowSeparatorLayout: Layout {
  var alignment: HorizontalAlignment = .center
  var spacing: CGFloat = 0

  func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    arrangement(
      for: subviews,
      maxWidth: proposal.width ?? .greatestFiniteMagnitude
    ).size
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    let arrangement = arrangement(for: subviews, maxWidth: bounds.width)
    applySeparatorVisibility(arrangement.separatorVisibility, subviews: subviews)

    for row in arrangement.rows {
      let xOffset = xOffset(for: row.width, in: bounds)
      for element in row.elements {
        subviews[element.index].place(
          at: CGPoint(
            x: bounds.minX + xOffset + element.origin.x,
            y: bounds.minY + row.originY + (row.height - element.size.height) / 2
          ),
          proposal: ProposedViewSize(element.size)
        )
      }
    }
  }
}

private extension HFlowSeparatorLayout {
  func arrangement(for subviews: Subviews, maxWidth: CGFloat) -> Arrangement {
    let availableWidth = availableWidth(for: maxWidth)
    let proposal = ProposedViewSize(width: availableWidth.isFinite ? availableWidth : nil, height: nil)
    let sizes = subviews.map { $0.sizeThatFits(proposal) }
    let separatorIndices = Set(
      subviews.indices.filter { subviews[$0][HFlowSeparatorRoleKey.self] }
    )

    var context = BuildContext(
      separatorVisibility: Dictionary(
        uniqueKeysWithValues: separatorIndices.map { ($0, true) }
      )
    )

    for index in subviews.indices {
      placeSubview(
        at: index,
        sizes: sizes,
        separatorIndices: separatorIndices,
        availableWidth: availableWidth,
        context: &context
      )
    }

    if !context.currentRow.elements.isEmpty {
      context.rows.append(context.currentRow)
    }

    let finalized = finalizeRows(context.rows)
    return Arrangement(
      rows: finalized.rows,
      size: finalized.size,
      separatorVisibility: context.separatorVisibility
    )
  }

  func availableWidth(for maxWidth: CGFloat) -> CGFloat {
    maxWidth.isFinite && maxWidth > 0 ? maxWidth : .greatestFiniteMagnitude
  }

  func placeSubview(
    at index: Int,
    sizes: [CGSize],
    separatorIndices: Set<Int>,
    availableWidth: CGFloat,
    context: inout BuildContext
  ) {
    let size = sizes[index]

    if separatorIndices.contains(index) {
      context.pendingSeparatorIndex = index
      return
    }

    guard !context.currentRow.isEmpty else {
      context.pendingSeparatorIndex = nil
      context.currentRow.append(index: index, size: size, spacing: spacing)
      return
    }

    if let separatorIndex = context.pendingSeparatorIndex {
      placeItemWithPendingSeparator(
        item: MeasuredSubview(index: index, size: size),
        separator: MeasuredSubview(index: separatorIndex, size: sizes[separatorIndex]),
        availableWidth: availableWidth,
        context: &context
      )
      return
    }

    if fits(sizes: [size], in: context.currentRow, maxWidth: availableWidth) {
      context.currentRow.append(index: index, size: size, spacing: spacing)
    } else {
      context.rows.append(context.currentRow)
      context.currentRow = Row()
      context.currentRow.append(index: index, size: size, spacing: spacing)
    }
  }

  func placeItemWithPendingSeparator(
    item: MeasuredSubview,
    separator: MeasuredSubview,
    availableWidth: CGFloat,
    context: inout BuildContext
  ) {
    if fits(sizes: [separator.size, item.size], in: context.currentRow, maxWidth: availableWidth) {
      context.separatorVisibility[separator.index] = false
      context.currentRow.append(index: separator.index, size: separator.size, spacing: spacing)
      context.currentRow.append(index: item.index, size: item.size, spacing: spacing)
    } else {
      context.rows.append(context.currentRow)
      context.currentRow = Row()
      context.currentRow.append(index: item.index, size: item.size, spacing: spacing)
    }

    context.pendingSeparatorIndex = nil
  }

  func fits(
    sizes: [CGSize],
    in row: Row,
    maxWidth: CGFloat
  ) -> Bool {
    let addedWidth = sizes.reduce(CGFloat.zero) { partialResult, size in
      partialResult + size.width
    }
    let addedSpacing = row.isEmpty ? 0 : spacing * CGFloat(sizes.count)
    return row.width + addedSpacing + addedWidth <= maxWidth
  }

  func finalizeRows(_ rows: [Row]) -> (rows: [Row], size: CGSize) {
    var positionedRows = rows
    var y: CGFloat = 0
    var width: CGFloat = 0

    for rowIndex in positionedRows.indices {
      positionedRows[rowIndex].originY = y
      y += positionedRows[rowIndex].height
      width = max(width, positionedRows[rowIndex].width)
    }

    return (positionedRows, CGSize(width: width, height: y))
  }

  func applySeparatorVisibility(
    _ visibility: [Int: Bool],
    subviews: Subviews
  ) {
    for index in subviews.indices where subviews[index][HFlowSeparatorRoleKey.self] {
      guard let binding = subviews[index][HFlowSeparatorVisibilityKey.self] else {
        continue
      }

      let shouldHide = visibility[index, default: true]
      guard binding.wrappedValue != shouldHide else {
        continue
      }

      Task { @MainActor in
        binding.wrappedValue = shouldHide
      }
    }
  }

  func xOffset(for rowWidth: CGFloat, in bounds: CGRect) -> CGFloat {
    switch alignment {
    case .leading:
      0
    case .trailing:
      bounds.width - rowWidth
    default:
      (bounds.width - rowWidth) / 2
    }
  }
}

private extension HFlowSeparatorLayout {
  struct Row {
    struct PlacedElement {
      let index: Int
      let size: CGSize
      let origin: CGPoint
    }

    var elements: [PlacedElement] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
    var originY: CGFloat = 0

    var isEmpty: Bool { elements.isEmpty }

    mutating func append(index: Int, size: CGSize, spacing: CGFloat) {
      let xPosition = isEmpty ? 0 : width + spacing
      let placedElement = PlacedElement(
        index: index,
        size: size,
        origin: CGPoint(x: xPosition, y: 0)
      )

      elements.append(placedElement)
      width = xPosition + size.width
      height = max(height, size.height)
    }
  }

  struct MeasuredSubview {
    let index: Int
    let size: CGSize
  }

  struct Arrangement {
    var rows: [Row]
    var size: CGSize
    var separatorVisibility: [Int: Bool]
  }

  struct BuildContext {
    var rows: [Row] = []
    var currentRow = Row()
    var pendingSeparatorIndex: Int?
    var separatorVisibility: [Int: Bool]
  }
}
