//
//  RomStoreTests.swift
//  senaling-macOSTests
//

import Foundation
import SenalingCore
import SwiftData
import Testing

@testable import senaling_macOS

struct RomStoreTests {

  @MainActor @Test func insertPersistsRomInActorOwnedContext() async throws {
    let schema = Schema([RomFile.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(
      for: schema,
      configurations: [configuration]
    )
    let romStore = RomStore(modelContainer: modelContainer)

    let folderURL = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString,
      directoryHint: .isDirectory
    )
    let romURL = folderURL.appending(path: "game.nes")

    try FileManager.default.createDirectory(
      at: folderURL,
      withIntermediateDirectories: true
    )
    defer {
      try? FileManager.default.removeItem(at: folderURL)
    }

    var rom = Data(repeating: 0, count: 16)
    rom.replaceSubrange(0..<4, with: Data("NES\u{001A}".utf8))
    try rom.write(to: romURL)

    var iterator = RomFolderScanner.RomFileAsyncIterator(
      folderURL: folderURL
    ).makeAsyncIterator()
    let result = try #require(await iterator.next())

    try await romStore.insert(
      bookmark: result.0,
      romInspection: result.1
    )

    let modelContext = ModelContext(modelContainer)
    let savedRoms = try modelContext.fetch(FetchDescriptor<RomFile>())

    #expect(savedRoms.count == 1)
    #expect(savedRoms.first?.UID == result.1.hashes.crc32)
  }
}
