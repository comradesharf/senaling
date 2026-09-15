//
//  RomFile.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 14/09/2026.
//
import Foundation
import SenalingCore
import SwiftData

@Model
final class RomFile: CustomStringConvertible {
  var description: String {
    "RomFile (UID: \(UID), romInspection: \(romInspection), bookmark: \(bookmark)"
  }

  @Attribute(.unique) var UID: String
  var bookmark: Data
  var romInspection: RomInspection

  init(bookmark: Data, romInspection: RomInspection) {
    self.UID = romInspection.hashes.crc32
    self.bookmark = bookmark
    self.romInspection = romInspection
  }
}
