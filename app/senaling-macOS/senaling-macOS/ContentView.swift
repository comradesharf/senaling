//
//  ContentView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @State private var isFileImporterShown = false

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
        Button("Add Folder", systemImage: "folder.badge.plus", action: scanFolderAction)
      }
    }.fileImporter(
      isPresented: $isFileImporterShown, allowedContentTypes: [.directory],
      onCompletion: handleScanFolder
    )
  }

  func scanFolderAction() {
    isFileImporterShown.toggle()
  }

  func handleScanFolder(result: Result<URL, any Error>) {
    switch result {
    case .success(let folderURL):
      guard folderURL.startAccessingSecurityScopedResource() else {
        return
      }
      defer { folderURL.stopAccessingSecurityScopedResource() }

      guard
        let fileList = FileManager.default.enumerator(
          at: folderURL,
          includingPropertiesForKeys: [.fileSizeKey, .nameKey]
        )
      else {
        print("Unable to get file list")
        return
      }

      for case let file as URL in fileList {
        guard file.startAccessingSecurityScopedResource() else {
          continue
        }
        print("File name", file)
        file.stopAccessingSecurityScopedResource()
      }

    case .failure(let error):
      print("Failed to scan folder", error)
    }
  }
}

#Preview {
  ContentView()
}
