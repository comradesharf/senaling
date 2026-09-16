//
//  ClrMameProParserTests.swift
//  senaling-macOSTests
//

import Foundation
import Testing

@testable import senaling_macOS

struct ClrMameProParserTests {

  @Test
  func parsesHeaderGamesAndRoms() throws {
    let database = try ClrMameProParser().parse(
      """
      clrmamepro (
        name "Nintendo - Nintendo Entertainment System"
        description "No-Intro DAT"
        version "2026.08.01"
        homepage "https://example.com"
      )
      game (
        name "10-Yard Fight (USA, Europe)"
        description "10-Yard Fight"
        region "USA"
        year 1985
        manufacturer "Nintendo"
        rom ( name "10-Yard Fight (USA, Europe).nes" size 40976 crc C986CDA2 md5 7B1D38579EDE25E20B3AAF870BE69C42 sha1 67F60E1D139DD85BAEF455B3B1228FBB5059BDAA )
      )
      """
    )

    #expect(database.header?.name == "Nintendo - Nintendo Entertainment System")
    #expect(database.header?.description == "No-Intro DAT")
    #expect(database.header?.version == "2026.08.01")
    #expect(database.header?.homepage == "https://example.com")
    #expect(database.games.count == 1)

    let game = try #require(database.games.first)
    #expect(game.name == "10-Yard Fight (USA, Europe)")
    #expect(game.description == "10-Yard Fight")
    #expect(game.region == "USA")
    #expect(game.year == "1985")
    #expect(game.manufacturer == "Nintendo")

    let rom = try #require(game.roms.first)
    #expect(rom.name == "10-Yard Fight (USA, Europe).nes")
    #expect(rom.size == 40_976)
    #expect(rom.crc == "C986CDA2")
    #expect(rom.md5 == "7B1D38579EDE25E20B3AAF870BE69C42")
    #expect(rom.sha1 == "67F60E1D139DD85BAEF455B3B1228FBB5059BDAA")
  }

  @Test
  func supportsEscapesMultipleRomsAndUnknownFields() throws {
    let database = try ClrMameProParser().parse(
      """
      game (
        name "A \\"quoted\\" game"
        unsupported ( nested value )
        rom ( name first.bin size 1 crc32 ABCD status nodump )
        rom ( name second.bin size 2 )
      )
      """
    )

    let game = try #require(database.games.first)
    #expect(game.name == "A \"quoted\" game")
    #expect(game.roms.count == 2)
    #expect(game.roms[0].crc == "ABCD")
    #expect(game.roms[0].status == "nodump")
    #expect(game.roms[1].name == "second.bin")
  }

  @Test
  func rejectsMalformedInput() {
    #expect(throws: ClrMameProParser.ParseError.self) {
      try ClrMameProParser().parse("game ( name \"Missing closing parenthesis\"")
    }

    #expect(throws: ClrMameProParser.ParseError.self) {
      try ClrMameProParser().parse("game ( name example rom ( name game.nes size nope ) )")
    }
  }
}
