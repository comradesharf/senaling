//
//  ContentView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import SwiftUI

struct ContentView: View {

  @State private var isPresented = false

  var body: some View {
    NavigationSplitView {
      List {
        Section(header: Text("Games")) {
          NavigationLink("NES", value: "NES")
        }
      }
    } detail: {
      Text("This is games")
    }
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

#Preview {
  ContentView()
    .environment(\.romFolderScanner, MockRomFolderScanner(isScanning: false))
}
