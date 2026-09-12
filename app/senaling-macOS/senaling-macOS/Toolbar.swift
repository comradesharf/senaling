//
//  Toolbar.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//

import SwiftUI

struct ToolbarExampleView: View {
  var body: some View {
    NavigationSplitView {
      List {
        Section(header: Text("ROMs")) {
          NavigationLink("NES", value: "NES")
        }
      }
    } detail: {
      Text("Select a flavor")
    }
  }
}

#Preview {
  ToolbarExampleView()
}
