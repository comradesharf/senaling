//
//  ClrMameProParser.swift
//  senaling-macOS
//

import Foundation

nonisolated struct ClrMameProParser: Sendable {

  enum ParseError: Error, Equatable, LocalizedError {
    case invalidUTF8
    case unexpectedEndOfInput
    case unexpectedToken(String, offset: Int)
    case unterminatedString(offset: Int)
    case missingValue(String, offset: Int)
    case invalidSize(String, offset: Int)

    var errorDescription: String? {
      switch self {
      case .invalidUTF8:
        "The DAT file is not valid UTF-8."
      case .unexpectedEndOfInput:
        "The DAT file ended unexpectedly."
      case .unexpectedToken(let token, let offset):
        "Unexpected token '\(token)' at offset \(offset)."
      case .unterminatedString(let offset):
        "Unterminated quoted string at offset \(offset)."
      case .missingValue(let key, let offset):
        "Missing value for '\(key)' at offset \(offset)."
      case .invalidSize(let value, let offset):
        "Invalid ROM size '\(value)' at offset \(offset)."
      }
    }
  }

  func parse(_ data: Data) throws -> ClrMameProDatabase {
    guard let source = String(data: data, encoding: .utf8) else {
      throw ParseError.invalidUTF8
    }

    return try parse(source)
  }

  func parse(_ source: String) throws -> ClrMameProDatabase {
    var parser = SyntaxParser(source: source)
    let entries = try parser.parseDocument()

    let headerEntry = entries.first {
      $0.key.caseInsensitiveCompare("clrmamepro") == .orderedSame
        || $0.key.caseInsensitiveCompare("emulator") == .orderedSame
    }

    let header = headerEntry.flatMap { entry -> ClrMameProDatabase.Header? in
      guard case .block(let fields) = entry.value else {
        return nil
      }

      return .init(
        name: fields.scalar(named: "name"),
        description: fields.scalar(named: "description"),
        version: fields.scalar(named: "version"),
        homepage: fields.scalar(named: "homepage")
      )
    }

    let games =
      try entries
      .filter {
        $0.key.caseInsensitiveCompare("game") == .orderedSame
          || $0.key.caseInsensitiveCompare("machine") == .orderedSame
          || $0.key.caseInsensitiveCompare("set") == .orderedSame
      }
      .map(Self.makeGame)

    return ClrMameProDatabase(header: header, games: games)
  }

  nonisolated private static func makeGame(
    from entry: Entry
  ) throws -> ClrMameProDatabase.Game {
    guard case .block(let fields) = entry.value else {
      throw ParseError.unexpectedToken(entry.key, offset: entry.offset)
    }
    guard let name = fields.scalar(named: "name") else {
      throw ParseError.missingValue("name", offset: entry.offset)
    }

    let roms =
      try fields
      .filter { $0.key.caseInsensitiveCompare("rom") == .orderedSame }
      .map(makeRom)

    return .init(
      name: name,
      description: fields.scalar(named: "description"),
      region: fields.scalar(named: "region"),
      year: fields.scalar(named: "year"),
      manufacturer: fields.scalar(named: "manufacturer"),
      cloneOf: fields.scalar(named: "cloneof"),
      roms: roms
    )
  }

  nonisolated private static func makeRom(
    from entry: Entry
  ) throws -> ClrMameProDatabase.Rom {
    guard case .block(let fields) = entry.value else {
      throw ParseError.unexpectedToken(entry.key, offset: entry.offset)
    }
    guard let name = fields.scalar(named: "name") else {
      throw ParseError.missingValue("name", offset: entry.offset)
    }

    let size: UInt64?
    if let value = fields.scalar(named: "size") {
      guard let parsedSize = UInt64(value) else {
        throw ParseError.invalidSize(value, offset: entry.offset)
      }
      size = parsedSize
    } else {
      size = nil
    }

    return .init(
      name: name,
      size: size,
      crc: fields.scalar(named: "crc") ?? fields.scalar(named: "crc32"),
      md5: fields.scalar(named: "md5"),
      sha1: fields.scalar(named: "sha1"),
      status: fields.scalar(named: "status")
    )
  }
}

nonisolated struct ClrMameProDatabase: Equatable, Sendable {
  let header: Header?
  let games: [Game]

  nonisolated struct Header: Equatable, Sendable {
    let name: String?
    let description: String?
    let version: String?
    let homepage: String?
  }

  nonisolated struct Game: Equatable, Sendable {
    let name: String
    let description: String?
    let region: String?
    let year: String?
    let manufacturer: String?
    let cloneOf: String?
    let roms: [Rom]
  }

  nonisolated struct Rom: Equatable, Sendable {
    let name: String
    let size: UInt64?
    let crc: String?
    let md5: String?
    let sha1: String?
    let status: String?
  }
}

extension Array where Element == ClrMameProParser.Entry {
  fileprivate nonisolated func scalar(named name: String) -> String? {
    first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.scalar
  }
}

extension ClrMameProParser {
  fileprivate nonisolated struct Entry {
    let key: String
    let value: Value
    let offset: Int

    var scalar: String? {
      guard case .scalar(let value) = value else {
        return nil
      }
      return value
    }
  }

  fileprivate nonisolated enum Value {
    case scalar(String)
    case block([Entry])
  }

  fileprivate nonisolated struct Token {
    nonisolated enum Kind {
      case value(String)
      case leftParenthesis
      case rightParenthesis
    }

    let kind: Kind
    let offset: Int
  }

  fileprivate nonisolated struct SyntaxParser {
    private var lexer: Lexer
    private var lookahead: Token?

    init(source: String) {
      self.lexer = Lexer(source: source)
    }

    mutating func parseDocument() throws -> [Entry] {
      var entries: [Entry] = []
      while try peek() != nil {
        entries.append(try parseEntry())
      }
      return entries
    }

    private mutating func parseEntry() throws -> Entry {
      let keyToken = try consume()
      guard case .value(let key) = keyToken.kind else {
        throw ParseError.unexpectedToken(keyToken.description, offset: keyToken.offset)
      }

      let valueToken = try consume()
      switch valueToken.kind {
      case .value(let value):
        return Entry(key: key, value: .scalar(value), offset: keyToken.offset)
      case .leftParenthesis:
        return Entry(
          key: key,
          value: .block(try parseBlock(openingOffset: valueToken.offset)),
          offset: keyToken.offset
        )
      case .rightParenthesis:
        throw ParseError.missingValue(key, offset: keyToken.offset)
      }
    }

    private mutating func parseBlock(openingOffset: Int) throws -> [Entry] {
      var entries: [Entry] = []
      while let token = try peek() {
        if case .rightParenthesis = token.kind {
          _ = try consume()
          return entries
        }
        entries.append(try parseEntry())
      }

      throw ParseError.unexpectedToken("(", offset: openingOffset)
    }

    private mutating func peek() throws -> Token? {
      if lookahead == nil {
        lookahead = try lexer.nextToken()
      }
      return lookahead
    }

    private mutating func consume() throws -> Token {
      guard let token = try peek() else {
        throw ParseError.unexpectedEndOfInput
      }
      lookahead = nil
      return token
    }
  }

  fileprivate nonisolated struct Lexer {
    private let source: String
    private var index: String.Index
    private var offset = 0

    init(source: String) {
      self.source = source
      self.index = source.startIndex
    }

    mutating func nextToken() throws -> Token? {
      skipWhitespace()
      guard index < source.endIndex else {
        return nil
      }

      let tokenOffset = offset
      switch source[index] {
      case "(":
        advance()
        return Token(kind: .leftParenthesis, offset: tokenOffset)
      case ")":
        advance()
        return Token(kind: .rightParenthesis, offset: tokenOffset)
      case "\"":
        return try quotedToken(offset: tokenOffset)
      default:
        return unquotedToken(offset: tokenOffset)
      }
    }

    private mutating func skipWhitespace() {
      while index < source.endIndex, source[index].isWhitespace {
        advance()
      }
    }

    private mutating func quotedToken(offset: Int) throws -> Token {
      advance()
      var value = ""

      while index < source.endIndex {
        let character = source[index]
        advance()

        if character == "\"" {
          return Token(kind: .value(value), offset: offset)
        }

        if character == "\\", index < source.endIndex {
          value.append(source[index])
          advance()
        } else {
          value.append(character)
        }
      }

      throw ParseError.unterminatedString(offset: offset)
    }

    private mutating func unquotedToken(offset: Int) -> Token {
      var value = ""
      while index < source.endIndex {
        let character = source[index]
        guard !character.isWhitespace, character != "(", character != ")" else {
          break
        }
        value.append(character)
        advance()
      }
      return Token(kind: .value(value), offset: offset)
    }

    private mutating func advance() {
      source.formIndex(after: &index)
      offset += 1
    }
  }
}

extension ClrMameProParser.Token {
  fileprivate nonisolated var description: String {
    switch kind {
    case .value(let value): value
    case .leftParenthesis: "("
    case .rightParenthesis: ")"
    }
  }
}
