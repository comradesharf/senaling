//
//  SwiftUIView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 15/09/2026.
//

import SwiftUI

struct ToolbarView: ViewModifier {

  @State private var isPresented = false

  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button(action: onButtonClick) {
            Label("Add Folder", systemImage: "folder.badge.plus")
          }
          .romFolderPicker(isPresented: $isPresented)
        }
      }
  }

  func onButtonClick() {
    isPresented.toggle()
  }
}

extension View {
  func appToolbar() -> some View {
    self.modifier(ToolbarView())
  }
}

#Preview {
  List {}
    .environment(\.romFolderScanner, MockRomFolderScanner(isScanning: false))
    .appToolbar()
}
