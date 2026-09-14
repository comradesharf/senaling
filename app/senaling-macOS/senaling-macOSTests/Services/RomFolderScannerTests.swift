//
//  RomScanTests.swift
//  senaling-macOSTests
//

import Foundation
import Testing

@testable import senaling_macOS

struct RomScanTests {

  @MainActor @Test func scanReturnsOnlySuccessfullyInspectedRomFiles() async throws {
    let fileManager = FileManager.default

    let folderURL = fileManager.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)

    let nestedFolderURL = folderURL.appending(path: "Nested", directoryHint: .isDirectory)
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

//    var results: [] = []
    for try await romInspection in RomFolderScanner(folderURL: folderURL) {
      print("found \(romInspection)")
    }

//    #expect(results == [validRom])
  }

  //  @Test func scanOfEmptyFolderReturnsZeroWithoutCallingHandler() async throws {
  //    let fileManager = FileManager.default
  //    let folderURL = fileManager.temporaryDirectory
  //      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
  //
  //    try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
  //    defer {
  //      try? fileManager.removeItem(at: folderURL)
  //    }
  //
  //    let foundURLs = FoundURLRecorder()
  //    let count = try await RomFolderScanner().scan(folderURL: folderURL) { fileURL in
  //      await foundURLs.record(fileURL)
  //    }
  //
  //    #expect(count == 0)
  //    #expect(await foundURLs.values.isEmpty)
  //  }

  //  @Test func scanJobStartsQueuedForItsFolder() {
  //    let folderURL = URL(filePath: "/tmp/roms", directoryHint: .isDirectory)
  //    let job = RomFolderScannerJob(folderURL)
  //
  //    #expect(job.folderURL == folderURL)
  //
  //    guard case .queued = job.state else {
  //      Issue.record("A new scan job should start in the queued state")
  //      return
  //    }
  //  }
}

private let validINesRom: Data = {
  var rom = Data(repeating: 0, count: 16)
  rom.replaceSubrange(0..<4, with: Data("NES\u{001A}".utf8))
  return rom
}()
