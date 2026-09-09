//
//  ContentView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @State private var files: [FileMetadata] = []
  @State private var isShowingFolderPicker = false
  @State private var selectedFolderName: String?
  @State private var importErrorMessage = ""
  @State private var isShowingImportError = false

  var body: some View {
    ZStack {
      AppBackground()

      VStack(alignment: .leading, spacing: AppDesign.sectionSpacing) {
        FolderHeader(
          folderName: selectedFolderName,
          fileCount: files.count,
          chooseFolder: showFolderPicker
        )

        if selectedFolderName == nil {
          ContentUnavailableView {
            Label("Choose a folder", systemImage: "folder.badge.plus")
          } description: {
            Text("Select a folder to see its files and metadata.")
          } actions: {
            ChooseFolderButton(action: showFolderPicker)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if files.isEmpty {
          ContentUnavailableView(
            "No Files",
            systemImage: "folder",
            description: Text("This folder contains no visible files.")
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          FileGrid(files: files)
        }
      }
      .padding(AppDesign.pagePadding)
    }
    .frame(minWidth: AppDesign.minimumWindowWidth, minHeight: AppDesign.minimumWindowHeight)
    .fileImporter(
      isPresented: $isShowingFolderPicker,
      allowedContentTypes: [.folder],
      allowsMultipleSelection: false,
      onCompletion: handleFolderSelection
    )
    .alert("Unable to Read Folder", isPresented: $isShowingImportError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(importErrorMessage)
    }
  }

  private func showFolderPicker() {
    isShowingFolderPicker = true
  }

  private func handleFolderSelection(_ result: Result<[URL], any Error>) {
    do {
      guard let folderURL = try result.get().first else { return }
      try loadFiles(from: folderURL)
    } catch {
      importErrorMessage = error.localizedDescription
      isShowingImportError = true
    }
  }

  private func loadFiles(from folderURL: URL) throws {
    let hasSecurityScopedAccess = folderURL.startAccessingSecurityScopedResource()
    defer {
      if hasSecurityScopedAccess {
        folderURL.stopAccessingSecurityScopedResource()
      }
    }

    let resourceKeys: Set<URLResourceKey> = [
      .contentModificationDateKey,
      .contentTypeKey,
      .fileSizeKey,
      .isRegularFileKey,
    ]
    let contents = try FileManager.default.contentsOfDirectory(
      at: folderURL,
      includingPropertiesForKeys: Array(resourceKeys),
      options: [.skipsHiddenFiles]
    )

    files = try contents.compactMap { url in
      let values = try url.resourceValues(forKeys: resourceKeys)
      guard values.isRegularFile == true else { return nil }
      return FileMetadata(url: url, resourceValues: values)
    }
    .sorted()
    selectedFolderName = folderURL.lastPathComponent
  }
}

#Preview {
  ContentView()
}
