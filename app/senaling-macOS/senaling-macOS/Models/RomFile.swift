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
  var bookmark: Data
  var romInspection: RomInspection

  init(bookmark: Data, romInspection: RomInspection) {
    self.bookmark = bookmark
    self.romInspection = romInspection
  }
}
