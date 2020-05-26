//
// SwiftGen
// Copyright © 2019 SwiftGen
// MIT Licence
//

import Commander
import Foundation
import PathKit
import Stencil
import StencilSwiftKit
import SwiftGenKit

// MARK: - Main

// swiftlint:disable:next closure_body_length
let main = Group {
  $0.noCommand = { path, group, parser in
    if parser.hasOption("help") {
      logMessage(.info, "Note: If you invoke swiftgen with no subcommand, it will default to `swiftgen config run`\n")
      throw GroupError.noCommand(path, group)
    } else {
      try ConfigCLI.run.run(parser)
    }
  }
  $0.group("config", "manage and run configuration files") {
    $0.addCommand("lint", "lint the configuration file", ConfigCLI.lint)
    $0.addCommand("run", "run commands listed in the configuration file", ConfigCLI.run)
    $0.addCommand("init", "create an initial configuration file", ConfigCLI.create)
    $0.addCommand("doc", "open the documentation for the configuration file on GitHub", ConfigCLI.doc)
  }

  $0.group("template", "manage custom templates") {
    $0.addCommand("list", "list bundled and custom templates", TemplatesCLI.list)
    $0.addCommand("which", "print path of a given named template", TemplatesCLI.which)
    $0.addCommand("cat", "print content of a given named template", TemplatesCLI.cat)
    $0.addCommand("doc", "open the documentation for templates on GitHub", TemplatesCLI.doc)
  }

  $0.group("run", "run individual parser commands without a config file") {
    for cmd in ParserCLI.allCommands {
      $0.addCommand(cmd.name, cmd.description, cmd.command())
    }
  }

  // Deprecated: Remove this in SwiftGen 7.0
  $0.group("templates", "DEPRECATED - old spelling for the `template` subcommand") {
    $0.addCommand("list", "list bundled and custom templates", TemplatesCLI.list)
    $0.addCommand("which", "print path of a given named template", TemplatesCLI.which)
    $0.addCommand("cat", "print content of a given named template", TemplatesCLI.cat)
    $0.addCommand("doc", "open the documentation for templates on GitHub", TemplatesCLI.cat)
  }

  for cmd in ParserCLI.allCommands {
    $0.addCommand(cmd.name, "DEPRECATED – use `swiftgen run \(cmd.name)` instead", cmd.command())
  }
  // Deprecation end
}

main.run(
  """
  SwiftGen v\(Version.swiftgen) (\
  Stencil v\(Version.stencil), \
  StencilSwiftKit v\(Version.stencilSwiftKit), \
  SwiftGenKit v\(Version.swiftGenKit))
  """
)
