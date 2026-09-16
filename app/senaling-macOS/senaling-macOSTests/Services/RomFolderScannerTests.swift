//
//  RomScanTests.swift
//  senaling-macOSTests
//

import Foundation
import SenalingCore
import Testing

@testable import senaling_macOS

struct RomFolderScannerTests {

  @MainActor @Test func scanReturnsOnlySuccessfullyInspectedRomFiles() async throws {
    let fileManager = FileManager.default

    let folderURL = fileManager.temporaryDirectory
      .appending(
        path: UUID().uuidString,
        directoryHint: .isDirectory
      )

    let nestedFolderURL = folderURL.appending(
      path: "Nested",
      directoryHint: .isDirectory
    )
    let topLevelFileURL = folderURL.appending(path: "game.nes")
    let nestedFileURL = nestedFolderURL.appending(path: "other.sfc")
    let hiddenFileURL = folderURL.appending(path: ".hidden-rom")

    try fileManager.createDirectory(at: nestedFolderURL, withIntermediateDirectories: true)
    defer {
      try? fileManager.removeItem(at: folderURL)
    }

    let validRom = validINesRom
    try Data("not a ROM".utf8).write(to: topLevelFileURL)
    try validRom.write(to: nestedFileURL)
    try validRom.write(to: hiddenFileURL)

    var results: [(Data, RomInspection)] = []
    for try await romFile in RomFolderScanner.RomFileAsyncIterator(folderURL: folderURL) {
      results.append(romFile)
    }

    #expect(results.count == 1)
  }
}

private let validINesRom: Data = {
  var rom = Data(repeating: 0, count: 16)
  rom.replaceSubrange(0..<4, with: Data("NES\u{001A}".utf8))
  return rom
}()
