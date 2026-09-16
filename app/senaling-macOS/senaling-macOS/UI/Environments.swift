//
//  Environments.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 15/09/2026.
//

import SwiftData
import SwiftUI

extension ModelContainer {

  static var shared: ModelContainer = {
    let schema = Schema([
      RomFile.self
    ])

    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    return try! ModelContainer(
      for: schema,
      configurations: [modelConfiguration]
    )
  }()
}

extension EnvironmentValues {

  @Entry var romFolderScanner: IRomFolderScanner = RomFolderScanner(
    modelContainer: ModelContainer.shared
  )
}

extension Window {

  func sharedContainer() -> some Scene {
    self.modelContainer(ModelContainer.shared)
  }
}
