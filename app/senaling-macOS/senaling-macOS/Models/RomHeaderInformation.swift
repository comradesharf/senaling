//
//  RomHeaderInformation.swift
//  senaling-macOS
//

import Foundation
import SwiftData

@Model
final class RomHeaderInformation {
  var name: String?
  var informationDescription: String?
  var version: String?
  var homepage: String?

  @Relationship(deleteRule: .cascade, inverse: \GameInformation.header)
  var games: [GameInformation]

  init(
    name: String? = nil,
    informationDescription: String? = nil,
    version: String? = nil,
    homepage: String? = nil,
    games: [GameInformation] = []
  ) {
    self.name = name
    self.informationDescription = informationDescription
    self.version = version
    self.homepage = homepage
    self.games = games

    for game in games {
      game.header = self
    }
  }

  convenience init(database: ClrMameProDatabase) {
    self.init(
      name: database.header?.name,
      informationDescription: database.header?.description,
      version: database.header?.version,
      homepage: database.header?.homepage,
      games: database.games.map(GameInformation.init)
    )
  }
}
