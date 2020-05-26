//
// SwiftGen
// Copyright © 2019 SwiftGen
// MIT Licence
//

import Commander
import PathKit

enum TemplatesCLI {
  static let list = command(
    Option<String>(
      "only",
      default: "",
      flag: "l",
      description: "If specified, only list templates valid for that specific subcommand",
      validator: isSubcommandName
    ),
    OutputDestination.cliOption
  ) { onlySubcommand, output in
    try ErrorPrettifier.execute {
      let commandsList = onlySubcommand.isEmpty
        ? ParserCLI.allCommands
        : [ParserCLI.command(named: onlySubcommand)].compactMap { $0 }

      let lines = commandsList.map(templatesList(subcommand:))
      try output.write(content: lines.joined(separator: "\n"))
      try output.write(
        content: """
          ---
          You can add custom templates in \(Path.appSupportTemplates).
          You can also specify templates by path using `templatePath` instead of `templateName`.
          For more information, see the documentation on GitHub.
          """
      )
    }
  }

  static let doc = command(
    Argument<String?>("subcommand", description: "the name of the subcommand for the template, like `strings`"),
    Argument<String?>("template", description: "the name of the template to find, like `swift5` or `flat-swift5`")
  ) { subcommand, template in
    var path = "templates/"
    if let subcommand = subcommand {
      // If we have a subcommand argument, ensure that is one of the allowed ones
      guard let parserCLI = ParserCLI.command(named: subcommand) else {
        let list = ParserCLI.allCommands.map { $0.name }.joined(separator: "/")
        throw ArgumentParserError(
          "If provided, the first argument must be the name of a subcommand (\(list))."
        )
      }
      path += "\(subcommand)/"

      // If we have a template argument, ensure that is one of the bundled templates for that subcommand
      if let template = template {
        let list = templates(in: Path.bundledTemplates + parserCLI.templateFolder).map(\.lastComponentWithoutExtension)
        guard list.contains(template) else {
          throw ArgumentParserError(
            """
            If provided, the 2nd argument must be the name of a bundled template for the given subcommand, i.e. one of:
            \(list.map { " - \($0)" }.joined(separator: "\n"))
            """
          )
        }
        path += "\(template).md"
      }
    }
    let url = gitHubDocURL(version: Version.swiftgen, path: path)
    logMessage(.info, "Opening documentation: \(url)")
    NSWorkspace.shared.open(url)
  }

  static let cat = pathCommandGenerator { (path: Path, output: OutputDestination) in
    let content: String = try path.read()
    try output.write(content: content)
  }

  static let which = pathCommandGenerator { (path: Path, output: OutputDestination) in
    try output.write(content: "\(path.description)\n")
  }
}

// MARK: Private Methods

private extension TemplatesCLI {
  static func templates(in path: Path) -> [Path] {
    guard let files = try? path.children() else { return [] }
    return files
      .filter { $0.extension == "stencil" }
      .sorted()
  }

  static func templatesList(subcommand: ParserCLI) -> String {
    func templatesFormattedList(in path: Path) -> [String] {
      templates(in: path + subcommand.templateFolder).map { "   - \($0.lastComponentWithoutExtension)" }
    }
    var lines = ["\(subcommand.name):"]
    lines.append("  custom:")
    lines.append(contentsOf: templatesFormattedList(in: Path.appSupportTemplates))
    lines.append("  bundled:")
    lines.append(contentsOf: templatesFormattedList(in: Path.bundledTemplates))
    return lines.joined(separator: "\n")
  }

  static func isSubcommandName(name: String) throws -> String {
    guard ParserCLI.allCommands.contains(where: { $0.name == name }) else {
      throw ArgumentError.invalidType(value: name, type: "subcommand", argument: "--only")
    }
    return name
  }

  // Defines a 'generic' command for doing an operation on a named template. It'll receive the following
  // arguments from the user:
  // - 'subcommand'
  // - 'template'
  // These will then be converted into an actual template path, and passed to the result closure.
  static func pathCommandGenerator(execute: @escaping (Path, OutputDestination) throws -> Void) -> CommandType {
    command(
      Argument<String>("subcommand", description: "the name of the subcommand for the template, like `xcassets`"),
      Argument<String>("template", description: "the name of the template to find, like `swift5` or `flat-swift5`"),
      OutputDestination.cliOption
    ) { subcommandName, templateName, output in
      try ErrorPrettifier.execute {
        guard let subcommand = ParserCLI.command(named: subcommandName) else { return }
        let template = TemplateRef.name(templateName)
        let path = try template.resolvePath(forSubcommand: subcommand.templateFolder)
        try execute(path, output)
      }
    }
  }
}
