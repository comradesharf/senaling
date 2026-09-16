//
//  RomInformation.swift
//  senaling-macOS
//

import Foundation
import SwiftData

@Model
final class RomInformation {
  var name: String
  var size: UInt64?
  var crc: String?
  var md5: String?
  var sha1: String?
  var status: String?

  var game: GameInformation?

  init(
    name: String,
    size: UInt64? = nil,
    crc: String? = nil,
    md5: String? = nil,
    sha1: String? = nil,
    status: String? = nil
  ) {
    self.name = name
    self.size = size
    self.crc = crc
    self.md5 = md5
    self.sha1 = sha1
    self.status = status
  }

  convenience init(_ rom: ClrMameProDatabase.Rom) {
    self.init(
      name: rom.name,
      size: rom.size,
      crc: rom.crc,
      md5: rom.md5,
      sha1: rom.sha1,
      status: rom.status
    )
  }
}
