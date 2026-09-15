//
//  ScanFolder.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 12/09/2026.
//

import SenalingCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ScanRomFolderView: ViewModifier {

  @Environment(\.romFolderScanner) private var romFolderScanner

  @Binding var isPresented: Bool

  func body(content: Content) -> some View {
    content
      .fileImporter(
        isPresented: $isPresented,
        allowedContentTypes: [.folder],
        onCompletion: onFolderSelected
      )
  }

  private func onFolderSelected(result: Result<URL, any Error>) {
    switch result {
    case .success(let folderURL):
      romFolderScanner.run(folderURL: folderURL)
    case .failure:
      print("")
    }
  }
}

extension View {
  func romFolderPicker(isPresented: Binding<Bool>) -> some View {
    self.modifier(ScanRomFolderView(isPresented: isPresented))
  }
}
