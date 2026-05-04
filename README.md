# InlineFlowSeparatorLayout

![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)
![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue.svg)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)

A SwiftUI flow layout that automatically inserts a separator between items and hides it when it would end up at the end of a line. Useful for tags, breadcrumbs, inline metadata, and compact lists built with the `Layout` protocol.

![Preview](preview.png)

## Installation

```swift
.package(url: "https://github.com/bernndr/InlineFlowSeparatorLayout.git", from: "0.1.0")
```

Alternatively, add the package from Xcode using the project's repository URL.

## Usage

```swift
import SwiftUI
import InlineFlowSeparatorLayout

struct ContentView: View {
    let tags = ["Swift", "SwiftUI", "iOS", "Xcode", "Layout", "SPM"]

    var body: some View {
        HFlowSeparator(spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
        } content: {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}
```

## Alignment

You can control the horizontal alignment of each row with the `alignment` parameter.

```swift
HFlowSeparator(alignment: .center, spacing: 8) {
  Image(systemName: "circle.fill")
    .font(.caption2)
    .foregroundStyle(.secondary)
} content: {
  ForEach(tags, id: \.self) { item in
    Text(item)
  }
}
```

## Requirements

- iOS 18+
- Swift 6
- Xcode with Swift Package Manager and `Layout` protocol support
