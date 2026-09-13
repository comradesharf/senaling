//
//  ContentView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import SwiftUI

struct ContentView: View {

  var body: some View {
    NavigationSplitView {
      List {
        Section(header: Text("Games")) {
          NavigationLink("NES", value: "NES")
        }
      }
    } detail: {
      Text("This is games")
    }.toolbar {
      ToolbarItem(placement: .primaryAction) {
        ScanRomFolderButton("Add Folder", systemImage: "folder.badge.plus")
      }
    }
  }
}

#Preview {
  ContentView()
}
