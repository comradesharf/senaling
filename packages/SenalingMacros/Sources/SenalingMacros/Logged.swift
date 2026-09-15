/// Adds a private, type-categorized `OSLog.Logger` named `logger`.
///
/// The file using this macro must import `Foundation` and `OSLog`.
@attached(member, names: named(logger))
public macro Logged() =
  #externalMacro(
    module: "SenalingMacrosPlugin",
    type: "LoggedMacro"
  )
