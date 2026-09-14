//
//  RomInspection.swift
//  SenalingCore
//
//  Created by Hishammuddin Sani on 11/09/2026.
//

import Foundation
import senaling_ffi

public struct RomInspection: Equatable, Sendable {
  public let fileSize: UInt64
  public let crc32: String
  public let md5: String
  public let sha1: String
  public let sha256: String
  public let container: String?
  public let header: String?
  public let mediaType: MediaType
  public let title: String?
  public let serial: String?
  public let productCode: String?
  public let volumeLabel: String?
  public let discID: String?
  public let region: String?
  public let revision: String?
  public let platform: String

  public enum MediaType: Equatable, Sendable {
    case cartridge
    case cdRom
    case dvdRom
    case bluRay
    case umd
    case floppyDisk
    case hardDisk
    case magneticTape
    case memoryCard
    case diskImage
    case tapeImage
    case romImage
    case archive
    case unknown
  }

  /// Inspects a ROM through a borrowed file handle.
  ///
  /// The handle remains owned by the caller, and its current offset is not changed.
  public static func inspect(fileHandle: FileHandle) throws -> Self {
    try inspect(fileDescriptor: fileHandle.fileDescriptor)
  }

  static func inspect(fileDescriptor: Int32) throws -> Self {
    let result = inspect_rom(fileDescriptor)
    defer { rom_inspection_result_free(result) }

    let diagnostic = decode(result.diagnostic)

    switch UInt32(result.error_code) {
    case ROM_INSPECTION_ERROR_CODE_OK.rawValue:
      guard result.inspection._0 else {
        throw RomInspectionError.internalFailure(
          diagnostic: diagnostic ?? "ROM inspection succeeded without returning an inspection"
        )
      }
      return Self(result.inspection._1)
    case ROM_INSPECTION_ERROR_CODE_INVALID_ARGUMENT.rawValue:
      throw RomInspectionError.invalidArgument(diagnostic: diagnostic)
    case ROM_INSPECTION_ERROR_CODE_INVALID_ROM.rawValue:
      throw RomInspectionError.invalidRom(diagnostic: diagnostic)
    case ROM_INSPECTION_ERROR_CODE_IO.rawValue:
      throw RomInspectionError.io(diagnostic: diagnostic)
    case ROM_INSPECTION_ERROR_CODE_INTERNAL.rawValue:
      throw RomInspectionError.internalFailure(diagnostic: diagnostic)
    default:
      throw RomInspectionError.internalFailure(
        diagnostic: diagnostic ?? "Unknown ROM inspection error code: \(result.error_code)"
      )
    }
  }

  private init(_ inspection: FfiRomInspection_t) {
    fileSize = inspection.file.size
    crc32 = Self.decode(inspection.hashes.crc32)
    md5 = Self.decode(inspection.hashes.md5)
    sha1 = Self.decode(inspection.hashes.sha1)
    sha256 = Self.decode(inspection.hashes.sha256)
    container = Self.decode(inspection.format.container)
    header = Self.decode(inspection.format.header)
    mediaType = Self.decode(inspection.format.media_type)
    title = Self.decode(inspection.identifiers.title)
    serial = Self.decode(inspection.identifiers.serial)
    productCode = Self.decode(inspection.identifiers.product_code)
    volumeLabel = Self.decode(inspection.identifiers.volume_label)
    discID = Self.decode(inspection.identifiers.disc_id)
    region = Self.decode(inspection.identifiers.region)
    revision = Self.decode(inspection.identifiers.revision)
    platform = Self.decode(inspection.platform)
  }

  private static func decode(_ value: Vec_uint8_t) -> String {
    String(
      decoding: UnsafeBufferPointer(start: value.ptr, count: value.len),
      as: UTF8.self
    )
  }

  private static func decode(_ value: Tuple2_bool_Vec_uint8_t) -> String? {
    value._0 ? decode(value._1) : nil
  }

  private static func decode(_ value: FfiMediaType_t) -> MediaType {
    switch UInt32(value) {
    case FFI_MEDIA_TYPE_CARTRIDGE.rawValue: .cartridge
    case FFI_MEDIA_TYPE_CD_ROM.rawValue: .cdRom
    case FFI_MEDIA_TYPE_DVD_ROM.rawValue: .dvdRom
    case FFI_MEDIA_TYPE_BLU_RAY.rawValue: .bluRay
    case FFI_MEDIA_TYPE_UMD.rawValue: .umd
    case FFI_MEDIA_TYPE_FLOPPY_DISK.rawValue: .floppyDisk
    case FFI_MEDIA_TYPE_HARD_DISK.rawValue: .hardDisk
    case FFI_MEDIA_TYPE_MAGNETIC_TAPE.rawValue: .magneticTape
    case FFI_MEDIA_TYPE_MEMORY_CARD.rawValue: .memoryCard
    case FFI_MEDIA_TYPE_DISK_IMAGE.rawValue: .diskImage
    case FFI_MEDIA_TYPE_TAPE_IMAGE.rawValue: .tapeImage
    case FFI_MEDIA_TYPE_ROM_IMAGE.rawValue: .romImage
    case FFI_MEDIA_TYPE_ARCHIVE.rawValue: .archive
    default: .unknown
    }
  }
}
