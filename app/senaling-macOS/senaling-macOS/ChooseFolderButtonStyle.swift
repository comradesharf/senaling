import SwiftUI

struct ChooseFolderButtonStyle: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(macOS 26.0, *) {
      content
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    } else {
      content
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
  }
}
