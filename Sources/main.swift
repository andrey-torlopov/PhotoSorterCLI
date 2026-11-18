import Darwin

exit(await CLIApplication().run(arguments: Array(CommandLine.arguments.dropFirst())))
