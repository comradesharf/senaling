//
//  senaling_macOSApp.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import SwiftData
import SwiftUI
import SenalingBinding

@main
struct senaling_macOSApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Item.self
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
      
    print("added value: \(SenalingBinding.add(left: 1, right: 2))", )

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
}
