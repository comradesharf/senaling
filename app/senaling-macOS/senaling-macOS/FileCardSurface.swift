import SwiftUI

struct FileCardSurface: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    content
      .background(.regularMaterial, in: .rect(cornerRadius: AppDesign.cardCornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius)
          .stroke(.separator, lineWidth: 1)
      }
  }
}
