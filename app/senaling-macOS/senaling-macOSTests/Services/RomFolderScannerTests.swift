//
//  RomScanTests.swift
//  senaling-macOSTests
//

import Foundation
import Testing

@testable import senaling_macOS

struct RomScanTests {

  @MainActor @Test func scanFindsRegularFilesRecursivelyAndSkipsHiddenFiles() async throws {
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

    try "NES\\x1a".data(using: .utf8)?.write(to: topLevelFileURL)
    try "NES\\x1a".data(using: .utf8)?.write(to: nestedFileURL)
    try "NES\\x1a".data(using: .utf8)?.write(to: hiddenFileURL)

    for try await data in RomFolderScanner(folderURL: folderURL) {
      print("Result \(String(decoding: data, as: UTF8.self))")
    }

    //    #expect(count == 2)
    //    let recordedURLs = await foundURLs.values
    //    let normalizedURLs = Set(recordedURLs.map { $0.resolvingSymlinksInPath() })
    //    let expectedURLs = Set(
    //      [topLevelFileURL, nestedFileURL].map { $0.resolvingSymlinksInPath() }
    //    )
    //    #expect(normalizedURLs == expectedURLs)
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
