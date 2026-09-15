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
final class RomFile {
  var ID: String
  var bookmark: Data
  var romInspection: RomInspection

  init(ID: String, bookmark: Data, romInspection: RomInspection) {
    self.ID = ID
    self.bookmark = bookmark
    self.romInspection = romInspection
  }
}
