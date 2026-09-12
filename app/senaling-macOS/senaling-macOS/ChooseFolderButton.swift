import SwiftUI

struct ChooseFolderButton: View {
  let action: () -> Void

  var body: some View {
    Button("Choose Folder", systemImage: "folder.badge.plus", action: action)
      .modifier(ChooseFolderButtonStyle())
      .accessibilityInputLabels(["Choose Folder", "Open Folder"])
  }
}
