//
//  RomDetailsServiceTest.swift
//  senaling-macOSTests
//
//  Created by Hishammuddin Sani on 16/09/2026.
//

import Foundation
import SwiftData
import Testing

@testable import senaling_macOS

struct RomDetailsServiceTest {

  @Test
  func fetchReturnsLatestDatabase() async throws {
    let database = try await RomDatabaseUpdater.Service().fetch()

    #expect(database.header?.name == "Nintendo - Nintendo Entertainment System")
    #expect(database.header?.version?.isEmpty == false)
    #expect(database.games.isEmpty == false)
  }

  @MainActor
  @Test
  func updateReplacesExistingDatabase() async throws {
    let schema = Schema([
      RomHeaderInformation.self,
      GameInformation.self,
      RomInformation.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let runner = RomDatabaseUpdater.Runner(modelContainer: container)

    try await runner.replaceDatabase(
      with: try database(version: "1", gameName: "Old Game", romName: "old.nes")
    )
    try await runner.replaceDatabase(
      with: try database(version: "2", gameName: "New Game", romName: "new.nes")
    )

    let context = ModelContext(container)
    let headers = try context.fetch(FetchDescriptor<RomHeaderInformation>())
    let games = try context.fetch(FetchDescriptor<GameInformation>())
    let roms = try context.fetch(FetchDescriptor<RomInformation>())

    #expect(headers.count == 1)
    #expect(headers.first?.version == "2")
    #expect(games.map(\.name) == ["New Game"])
    #expect(roms.map(\.name) == ["new.nes"])
  }

  private func database(
    version: String,
    gameName: String,
    romName: String
  ) throws -> ClrMameProDatabase {
    try ClrMameProParser().parse(
      """
      clrmamepro (
        name "Test Database"
        version "\(version)"
      )
      game (
        name "\(gameName)"
        rom ( name "\(romName)" size 16 crc ABCDEF12 )
      )
      """
    )
  }
}
