import Foundation
import PhotoSorterCore

enum InputError: Error, Equatable {
    case endOfInput
}

/// Terminal adapter: EOF is cancellation, never a retry or a default answer.
final class InputDialog {
    private(set) var localization: CLILocalization
    private let dateFormattingService = DateFormattingService.shared
    private let readInput: () -> String?
    private let writeOutput: (String) -> Void
    private let validatePath: (URL) -> Bool

    init(
        language: CLILanguage = .en,
        readInput: @escaping () -> String? = { readLine(strippingNewline: true) },
        writeOutput: @escaping (String) -> Void = { print($0, terminator: "") },
        validatePath: @escaping (URL) -> Bool = { PathValidator.validate($0) }
    ) {
        self.localization = CLILocalization(language: language)
        self.readInput = readInput
        self.writeOutput = writeOutput
        self.validatePath = validatePath
    }

    func use(language: CLILanguage) { localization = CLILocalization(language: language) }

    func writeLine(_ message: String) { writeOutput(message + "\n") }

    private func readRequiredLine() throws -> String {
        guard let line = readInput() else { throw InputError.endOfInput }
        return line
    }

    func requestYesNo(text: String, defaultYes: Bool = true) throws -> Bool {
        while true {
            writeOutput("\(text) \(localization(defaultYes ? .yesDefault : .noDefault)): ")
            let input = try readRequiredLine().trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["y", "yes", "д", "да"].contains(input) || (input.isEmpty && defaultYes) { return true }
            if ["n", "no", "н", "нет"].contains(input) || (input.isEmpty && !defaultYes) { return false }
            writeLine(localization(.invalidAnswer))
        }
    }

    func requestPath(text: String) throws -> String {
        while true {
            writeOutput("\(text): ")
            let path = try readRequiredLine()
            if !path.isEmpty && validatePath(URL(fileURLWithPath: path)) { return path }
            writeLine(localization(.invalidPath))
        }
    }

    func requestDate(text: String) throws -> Date {
        let predefinedFormats: [DateFormattingService.Format] = [
            .yyyyMMddHHmm, .yyyyMMdd, .ddMMyyyyHHmm, .ddMMyyyy
        ]
        while true {
            writeOutput("\(text): ")
            let input = try readRequiredLine()
            for format in predefinedFormats {
                if let date = dateFormattingService.parse(input, using: format) { return date }
            }
            writeLine(localization(.dateNotParsed))
            let format = try requestString(text: localization(.dateFormatPrompt))
            if let date = dateFormattingService.parse(input, using: .custom(format)) { return date }
            writeLine(localization(.invalidDateFormat))
        }
    }

    func requestString(text: String) throws -> String {
        writeOutput("\(text): ")
        return try readRequiredLine()
    }
}
