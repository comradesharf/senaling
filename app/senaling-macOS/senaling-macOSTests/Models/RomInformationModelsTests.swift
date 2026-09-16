//
//  RomInformationModelsTests.swift
//  senaling-macOSTests
//

import SwiftData
import Testing

@testable import senaling_macOS

struct RomInformationModelsTests {

  @MainActor
  @Test
  func convertsParserValuesIntoRelatedModels() throws {
    let database = try ClrMameProParser().parse(
      """
      clrmamepro (
        name "Nintendo - Nintendo Entertainment System"
        description "No-Intro DAT"
        version "2026.08.01"
        homepage "https://example.com"
      )
      game (
        name "Example Game"
        region "USA"
        rom ( name example.nes size 40976 crc C986CDA2 )
      )
      """
    )

    let header = RomHeaderInformation(database: database)
    let game = try #require(header.games.first)
    let rom = try #require(game.roms.first)

    #expect(header.name == "Nintendo - Nintendo Entertainment System")
    #expect(header.informationDescription == "No-Intro DAT")
    #expect(game.header === header)
    #expect(game.name == "Example Game")
    #expect(rom.game === game)
    #expect(rom.name == "example.nes")
    #expect(rom.size == 40_976)
    #expect(rom.crc == "C986CDA2")
  }

  @MainActor
  @Test
  func deletingHeaderCascadesThroughGamesAndRoms() throws {
    let schema = Schema([
      RomHeaderInformation.self,
      GameInformation.self,
      RomInformation.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let context = ModelContext(container)

    let rom = RomInformation(name: "example.nes", size: 16)
    let game = GameInformation(name: "Example Game", roms: [rom])
    let header = RomHeaderInformation(name: "Example DAT", games: [game])

    context.insert(header)
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<RomHeaderInformation>()) == 1)
    #expect(try context.fetchCount(FetchDescriptor<GameInformation>()) == 1)
    #expect(try context.fetchCount(FetchDescriptor<RomInformation>()) == 1)

    context.delete(header)
    try context.save()

    #expect(try context.fetchCount(FetchDescriptor<RomHeaderInformation>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<GameInformation>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<RomInformation>()) == 0)
  }
}
