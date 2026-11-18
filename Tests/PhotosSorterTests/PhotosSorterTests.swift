import Testing
@testable import PhotosSorter

struct CLIApplicationTests {
    @Test("Help and version do not read input or dispatch file operations")
    func informationalArguments() async {
        for arguments in [["--help"], ["-h"], ["--version"]] {
            let terminal = TerminalFixture()
            var output = ""
            var operations = 0
            let app = CLIApplication(input: terminal.dialog(), writeOutput: { output += $0 },
                                     writeError: { _ in }, performOperation: { _, _ in operations += 1 })
            #expect(await app.run(arguments: ["--language", "en"] + arguments) == 0)
            #expect(terminal.readCount == 0)
            #expect(operations == 0)
            #expect(output.contains(arguments == ["--version"] ? BuildVersion.current : "Usage:"))
        }
    }

    @Test("Unknown or combined arguments fail before reading input")
    func invalidArguments() async {
        for arguments in [["--unknown"], ["--help", "--version"], ["photo.jpg"]] {
            let terminal = TerminalFixture()
            var errors = ""
            let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in },
                                     writeError: { errors += $0 })
            #expect(await app.run(arguments: arguments) == 64)
            #expect(terminal.readCount == 0)
            #expect(errors.contains("--help"))
        }
    }

    @Test("Menu EOF exits without launching an operation")
    func menuEOF() async {
        let terminal = TerminalFixture()
        var operations = 0
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { _ in },
                                 performOperation: { _, _ in operations += 1 })
        #expect(await app.run(arguments: []) == 0)
        #expect(operations == 0)
        #expect(terminal.readCount == 1)
    }

    @Test("The six menu choices route once and explicit exit stops reading")
    func routing() async {
        let terminal = TerminalFixture(["invalid", "1", "2", "3", "4", "5", "6", "0", "1"])
        var operations: [PhotoOperation] = []
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { _ in },
                                 performOperation: { operation, _ in operations.append(operation) })
        #expect(await app.run(arguments: []) == 0)
        #expect(operations == [.convertDngToHeic, .sortPhotos, .fixDate, .forceDateSet,
                               .checkValidDateAndName, .convertPngToHeic])
        #expect(terminal.readCount == 8)
    }

    @Test("EOF in a nested operation ends the application rather than reopening the menu")
    func nestedEOF() async {
        let terminal = TerminalFixture(["1"])
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { _ in })
        #expect(await app.run(arguments: []) == 0)
        #expect(terminal.readCount == 2)
    }

    @Test("The interactive menu shows the same version as --version")
    func menuVersion() async {
        let terminal = TerminalFixture(["0"])
        var output = ""
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { output += $0 },
                                 writeError: { _ in })
        #expect(await app.run(arguments: []) == 0)
        #expect(output.contains("v.\(BuildVersion.current)"))
    }
}
