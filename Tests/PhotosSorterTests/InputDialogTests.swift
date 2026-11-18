import Foundation
import Testing
@testable import PhotosSorter

final class TerminalFixture {
    private var lines: [String]
    private(set) var output = ""
    private(set) var readCount = 0

    init(_ lines: [String] = []) { self.lines = lines }

    func dialog(validatePath: @escaping (URL) -> Bool = { _ in true }) -> InputDialog {
        InputDialog(readInput: {
            self.readCount += 1
            return self.lines.isEmpty ? nil : self.lines.removeFirst()
        }, writeOutput: { self.output += $0 }, validatePath: validatePath)
    }
}

struct InputDialogTests {
    @Test("EOF never confirms a question or retries indefinitely")
    func eofYesNo() {
        let terminal = TerminalFixture()
        #expect(throws: InputError.endOfInput) {
            try terminal.dialog().requestYesNo(text: "Delete?", defaultYes: true)
        }
        #expect(terminal.readCount == 1)
    }

    @Test("EOF propagates from every input kind")
    func eofInputs() {
        #expect(throws: InputError.endOfInput) { try TerminalFixture().dialog().requestPath(text: "Folder") }
        #expect(throws: InputError.endOfInput) { try TerminalFixture().dialog().requestDate(text: "Date") }
        #expect(throws: InputError.endOfInput) { try TerminalFixture().dialog().requestString(text: "Text") }
        #expect(throws: InputError.endOfInput) {
            try TerminalFixture(["invalid date"]).dialog().requestDate(text: "Date")
        }
    }

    @Test("Invalid answer retries and empty answer respects the configured default")
    func answers() throws {
        let terminal = TerminalFixture(["maybe", ""])
        #expect(try terminal.dialog().requestYesNo(text: "Delete?", defaultYes: false) == false)
        #expect(terminal.readCount == 2)
        #expect(terminal.output.contains("Invalid input"))
        #expect(try TerminalFixture(["Y"]).dialog().requestYesNo(text: "Continue?") == true)
    }

    @Test("Paths keep spaces and Unicode; an empty path is not the current directory")
    func paths() throws {
        let path = "/tmp/Фото family"
        let terminal = TerminalFixture(["", "/missing", path])
        #expect(try terminal.dialog(validatePath: { $0.path == path }).requestPath(text: "Folder") == path)
        #expect(terminal.readCount == 3)
    }

    @Test("Custom date input reaches the actual date parser unchanged")
    func customDate() throws {
        let terminal = TerminalFixture(["day=12 month=03 year=2024", "'day='dd 'month='MM 'year='yyyy"])
        let result = try terminal.dialog().requestDate(text: "Date")
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2024)
        #expect(components.month == 3)
        #expect(components.day == 12)
    }
}
