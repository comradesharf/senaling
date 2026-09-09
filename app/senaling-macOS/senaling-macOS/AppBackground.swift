import SwiftUI

struct AppBackground: View {
  var body: some View {
    LinearGradient(
      colors: [
        Color.accentColor.opacity(0.18),
        Color(nsColor: .windowBackgroundColor),
        Color.purple.opacity(0.12),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
  }
}
