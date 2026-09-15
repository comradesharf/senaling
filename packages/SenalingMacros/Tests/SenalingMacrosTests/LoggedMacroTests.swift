import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import SenalingMacrosPlugin

private let testMacros: [String: Macro.Type] = [
  "Logged": LoggedMacro.self
]

final class LoggedMacroTests: XCTestCase {
  func testGeneratesLoggerUsingAttachedTypeName() {
    assertMacroExpansion(
      """
      @Logged
      final class RomFolderScanner {}
      """,
      expandedSource: """
        final class RomFolderScanner {

          private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
            category: "RomFolderScanner"
          )
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }

  func testSupportsNestedActor() {
    assertMacroExpansion(
      """
      final class RomFolderScanner {
        @Logged
        private actor Runner {
        }
      }
      """,
      expandedSource: """
        final class RomFolderScanner {
          private actor Runner {

            private static let logger = Logger(
              subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
              category: "Runner"
            )
          }
        }
        """,
      macros: testMacros,
      indentationWidth: .spaces(2)
    )
  }
}
