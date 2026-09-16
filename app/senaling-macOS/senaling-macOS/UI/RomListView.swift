//
//  RomListView.swift
//  senaling-macOS
//
//  Created by Hishammuddin Sani on 15/09/2026.
//

import SenalingCore
import SwiftData
import SwiftUI

struct RomListView: View {

  @Query() var romFiles: [RomFile]

  var body: some View {
    List {
      ForEach(romFiles) {
        Text($0.UID)
        Text($0.romInspection.hashes.crc32)
          .textSelection(.enabled)
        Text($0.romInspection.hashes.md5)
          .textSelection(.enabled)
        Text($0.romInspection.hashes.sha1)
          .textSelection(.enabled)
        Text($0.romInspection.hashes.sha256)
          .textSelection(.enabled)
      }
    }
  }
}

#Preview {
  RomListView()
}
