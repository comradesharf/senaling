//
//  RomInspectionError.swift
//  SenalingCore
//

import Foundation

public enum RomInspectionError: Error, Equatable, Sendable {
  case invalidArgument(diagnostic: String?)
  case invalidRom(diagnostic: String?)
  case io(diagnostic: String?)
  case internalFailure(diagnostic: String?)
}

extension RomInspectionError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidArgument(let diagnostic):
      diagnostic ?? "The ROM inspection argument is invalid"
    case .invalidRom(let diagnostic):
      diagnostic ?? "The file is not a supported ROM"
    case .io(let diagnostic):
      diagnostic ?? "The ROM could not be read"
    case .internalFailure(let diagnostic):
      diagnostic ?? "ROM inspection failed internally"
    }
  }
}
