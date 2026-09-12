//
//  ContentView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 08/09/2026.
//

import Foundation
import SenalingCore
import SwiftUI
import UniformTypeIdentifiers

enum ScanError: Error {
  case folderAccessFailed
  case fileAccessFailed

  var title: String {
    switch self {
    case .fileAccessFailed:
      return "Failed to access file"
    case .folderAccessFailed:
      return "Failed to access folder"
    }
  }

  var message: String {
    switch self {
    case .fileAccessFailed:
      return "Unable to access the selected file."
    case .folderAccessFailed:
      return "Unable to access the selected folder."
    }
  }
}

struct ContentView: View {
  @State private var isFileImporterShown = false
  @State private var scanError: ScanError? = nil
  private var isAlertPresented: Binding<Bool> {
    Binding(
      get: { scanError != nil },
      set: { isPresented in
        if !isPresented {
          scanError = nil
        }
      }
    )
  }

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
        Button(
          "Add Folder",
          systemImage: "folder.badge.plus",
          action: scanFolderAction
        )
      }
    }.fileImporter(
      isPresented: $isFileImporterShown, allowedContentTypes: [.directory],
      onCompletion: handleScanFolder
    ).alert(scanError?.title ?? "", isPresented: isAlertPresented, presenting: scanError) {
      _ in
      Button("OK") {
        scanError = nil
      }
    } message: { alertMessage in
      Text(alertMessage.message)
    }
  }

  func scanFolderAction() {
    isFileImporterShown.toggle()
  }

  func handleScanFolder(result: Result<URL, any Error>) {
    do {
      let folderURL = try result.get()
      guard folderURL.startAccessingSecurityScopedResource() else {
        scanError = ScanError.folderAccessFailed
        return
      }
      defer {
        folderURL.stopAccessingSecurityScopedResource()
      }

      let fileURLs = try FileManager.default.contentsOfDirectory(
        at: folderURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )

      for fileURL in fileURLs {
        guard
          let file = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
          file.isRegularFile ?? true
        else {
          continue
        }

        let handle = try FileHandle(forReadingFrom: fileURL)
        defer {
          try? handle.close()
        }

        guard let leadingBytes = try? handle.read(upToCount: 512) else {
          continue
        }

        let type = SignatureCheck.getSignatureCheck(
          leadingBytes: leadingBytes
        )

        guard type != nil else {
          continue
        }

        print("Detected file type: \(type!) for \(file)")
      }
    } catch {
      scanError = ScanError.folderAccessFailed
    }
  }
}

#Preview {
  ContentView()
}
