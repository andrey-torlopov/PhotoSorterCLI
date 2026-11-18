import Testing
@testable import PhotosSorter

struct ConvertToHeicScriptTests {
    @Test("Conversion requires both a path and a deletion answer before starting")
    func eofBeforeConversion() async {
        for lines in [[], ["/tmp/test-input"]] {
            let script = ConvertToHeicScript(inputDialog: TerminalFixture(lines).dialog())
            await #expect(throws: InputError.endOfInput) { try await script.run(from: .png) }
        }
    }
}
