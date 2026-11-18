import Testing
@testable import PhotosSorter

struct FixDateScriptTests {
    @Test("Date operations stop at EOF before touching any file")
    func eofBeforeDateOperations() async {
        await #expect(throws: InputError.endOfInput) {
            try await FixDateScript(inputDialog: TerminalFixture().dialog()).runFixDate()
        }
        await #expect(throws: InputError.endOfInput) {
            try await FixDateScript(inputDialog: TerminalFixture().dialog()).runCheckValidDateAndName()
        }
        #expect(throws: InputError.endOfInput) {
            try FixDateScript(inputDialog: TerminalFixture(["/tmp/test-input"]).dialog()).runForceSetDate()
        }
    }
}
