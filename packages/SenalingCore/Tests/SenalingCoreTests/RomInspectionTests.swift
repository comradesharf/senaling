import Foundation
import Testing

@testable import SenalingCore

@Test func inspectsRomWithoutTakingOwnershipOrChangingTheFileOffset() throws {
  let url = try temporaryRomURL(contents: validINesRom, name: "valid")
  defer { try? FileManager.default.removeItem(at: url) }

  let fileHandle = try FileHandle(forReadingFrom: url)
  defer { try? fileHandle.close() }
  try fileHandle.seek(toOffset: 7)

  let inspection = try RomInspection.inspect(fileHandle: fileHandle)

  #expect(inspection.fileSize == 16)
  #expect(inspection.container == "iNES")
  #expect(inspection.header == "iNES")
  #expect(inspection.mediaType == .cartridge)
  #expect(inspection.platform == "NES")
  #expect(inspection.title == nil)
  #expect(inspection.crc32.count == 8)
  #expect(inspection.md5.count == 32)
  #expect(inspection.sha1.count == 40)
  #expect(inspection.sha256.count == 64)
  #expect(try fileHandle.offset() == 7)
}

@Test func throwsStableErrorForUnsupportedRom() throws {
  let url = try temporaryRomURL(contents: Data("not a rom".utf8), name: "unsupported")
  defer { try? FileManager.default.removeItem(at: url) }

  let fileHandle = try FileHandle(forReadingFrom: url)
  defer { try? fileHandle.close() }

  #expect(throws: RomInspectionError.invalidRom(diagnostic: "unsupported NES ROM format")) {
    try RomInspection.inspect(fileHandle: fileHandle)
  }
}

@Test func rejectsInvalidFileDescriptor() {
  #expect(
    throws: RomInspectionError.invalidArgument(
      diagnostic: "file descriptor must be non-negative"
    )
  ) {
    try RomInspection.inspect(fileDescriptor: -1)
  }
}

private let validINesRom: Data = {
  var rom = Data(repeating: 0, count: 16)
  rom.replaceSubrange(0..<4, with: Data("NES\u{001A}".utf8))
  return rom
}()

private func temporaryRomURL(contents: Data, name: String) throws -> URL {
  let url = FileManager.default.temporaryDirectory
    .appending(path: "senaling-swift-rom-inspection-\(name)-\(UUID().uuidString)")
  try contents.write(to: url)
  return url
}
