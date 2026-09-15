import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum LoggedMacroError: Error, CustomStringConvertible {
  case unsupportedDeclaration

  var description: String {
    switch self {
    case .unsupportedDeclaration:
      "@Logged can only be attached to a class, struct, actor, or enum"
    }
  }
}

public struct LoggedMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let typeName = try typeName(of: declaration)

    return [
      """
      private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "comradesharf",
        category: \(literal: typeName)
      )
      """
    ]
  }

  private static func typeName(
    of declaration: some DeclGroupSyntax
  ) throws -> String {
    if let declaration = declaration.as(ClassDeclSyntax.self) {
      return declaration.name.text
    }

    if let declaration = declaration.as(StructDeclSyntax.self) {
      return declaration.name.text
    }

    if let declaration = declaration.as(ActorDeclSyntax.self) {
      return declaration.name.text
    }

    if let declaration = declaration.as(EnumDeclSyntax.self) {
      return declaration.name.text
    }

    throw LoggedMacroError.unsupportedDeclaration
  }
}

@main
struct SenalingMacrosPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    LoggedMacro.self
  ]
}
