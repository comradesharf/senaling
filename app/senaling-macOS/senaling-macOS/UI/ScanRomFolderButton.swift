//
//  ScanFolder.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ScanRomFolderButton: View {
  @Environment(\.romFolderScannerStore) private var romFolderScannerStore

  private var titleKey: LocalizedStringResource
  private var systemImage: String

  @State private var isPresented = false

  init(_ titleKey: LocalizedStringResource, systemImage: String) {
    self.titleKey = titleKey
    self.systemImage = systemImage
  }

  init(_ titleKey: LocalizedStringResource) {
    self.init(titleKey, systemImage: "")
  }

  var body: some View {
    Button(titleKey, systemImage: systemImage, action: onButtonClicked)
      .fileImporter(
        isPresented: $isPresented,
        allowedContentTypes: [.folder],
        onCompletion: onFolderSelected
      )
  }

  func onButtonClicked() {
    isPresented.toggle()
  }

  func onFolderSelected(result: Result<URL, any Error>) {
    switch result {
    case .success(let folderURL):
      romFolderScannerStore.start(folderURL)
    case .failure(let err):
      print("Failed", err)
    }
  }
}

#Preview {
  ScanRomFolderButton("Test", systemImage: "folder.badge.plus")
    .environment(\.romFolderScannerStore, MockedRomFolderScannerStore())
}
