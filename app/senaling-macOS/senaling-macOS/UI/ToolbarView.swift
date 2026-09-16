//
//  SwiftUIView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 15/09/2026.
//

import SwiftUI

struct ToolbarView: ViewModifier {

  @Environment(\.romDatabaseUpdater) private var romDatabaseUpdater
  @Environment(\.romFolderScanner) private var romFolderScanner

  @State private var isPresented = false

  func body(content: Content) -> some View {
    content
      .toolbar {
        ToolbarItem {
          Button(action: onUpdateDatabase) {
            Label("Update Database", systemImage: "arrow.clockwise")
          }
          .disabled(romDatabaseUpdater.isUpdating)
        }
        ToolbarItem(placement: .primaryAction) {
          Button(action: onPickFolder) {
            Label("Add Folder", systemImage: "folder.badge.plus")
          }
          .disabled(romFolderScanner.isScanning)
          .romFolderPicker(isPresented: $isPresented)
        }
      }
  }

  func onPickFolder() {
    isPresented.toggle()
  }

  func onUpdateDatabase() {
    romDatabaseUpdater.run()
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
