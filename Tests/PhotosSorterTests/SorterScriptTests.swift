import Testing
@testable import PhotosSorter

struct SorterScriptTests {
    @Test("Sorting does not start from incomplete configuration")
    func incompleteConfiguration() async {
        for lines in [[], ["/input"], ["/input", "/output", "y"]] {
            let script = SorterScript(inputDialog: TerminalFixture(lines).dialog())
            await #expect(throws: InputError.endOfInput) { try await script.run() }
        }
    }

    @Test("Default deletion answer preserves originals in the production configuration")
    func preservesOriginals() throws {
        let terminal = TerminalFixture(["/input", "/output", "", "n", "", "n", "", "y"])
        let candidate = try SorterScript(inputDialog: terminal.dialog()).prepareInputParameters()
        let configuration = try #require(candidate)
        #expect(configuration.disposition == .keepOriginal)
        #expect(configuration.inputFolder.path == "/input")
        #expect(configuration.outputFolder.path == "/output")
    }
}
