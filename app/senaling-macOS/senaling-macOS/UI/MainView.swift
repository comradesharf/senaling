//
//  MainWindow.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 15/09/2026.
//

import SwiftUI

struct MainView: View {

  var body: some View {
    NavigationSplitView {
      List {
        ForEach(Platform.allCases) { plaform in
          NavigationLink(plaform.name, value: plaform.id)
        }
      }
    } content: {
      RomListView()
    } detail: {
      Text("No ROM selected")
    }
    .appToolbar()
  }

  enum Platform: CaseIterable, Identifiable {
    case nes

    var id: String {
      switch self {
      case .nes:
        return "nes"
      }
    }

    var name: String {
      switch self {
      case .nes:
        return "NES"
      }
    }
  }
}

#Preview {
  MainView()
}
