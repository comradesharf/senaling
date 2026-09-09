import SwiftUI

struct FileCardSurface: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(macOS 26.0, *) {
      content.glassEffect(.regular, in: .rect(cornerRadius: AppDesign.cardCornerRadius))
    } else {
      content
        .background(.regularMaterial, in: .rect(cornerRadius: AppDesign.cardCornerRadius))
        .overlay {
          RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius)
            .stroke(.separator, lineWidth: 1)
        }
    }
  }
}
