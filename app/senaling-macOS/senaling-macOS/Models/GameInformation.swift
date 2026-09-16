//
//  GameInformation.swift
//  senaling-macOS
//

import Foundation
import SwiftData

@Model
final class GameInformation {
  var name: String
  var informationDescription: String?
  var region: String?
  var year: String?
  var manufacturer: String?
  var cloneOf: String?

  var header: RomHeaderInformation?

  @Relationship(deleteRule: .cascade, inverse: \RomInformation.game)
  var roms: [RomInformation]

  init(
    name: String,
    informationDescription: String? = nil,
    region: String? = nil,
    year: String? = nil,
    manufacturer: String? = nil,
    cloneOf: String? = nil,
    roms: [RomInformation] = []
  ) {
    self.name = name
    self.informationDescription = informationDescription
    self.region = region
    self.year = year
    self.manufacturer = manufacturer
    self.cloneOf = cloneOf
    self.roms = roms

    for rom in roms {
      rom.game = self
    }
  }

  convenience init(_ game: ClrMameProDatabase.Game) {
    self.init(
      name: game.name,
      informationDescription: game.description,
      region: game.region,
      year: game.year,
      manufacturer: game.manufacturer,
      cloneOf: game.cloneOf,
      roms: game.roms.map(RomInformation.init)
    )
  }
}
