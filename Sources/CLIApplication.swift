import Foundation

/// Owns terminal input and dispatch; photo processing remains in PhotoSorterCore.
struct CLIApplication {
    private let input: InputDialog
    private let writeOutput: (String) -> Void
    private let writeError: (String) -> Void
    private let performOperation: (PhotoOperation, InputDialog) async throws -> Void
    private let environment: [String: String]
    private let preferredLanguages: [String]

    init(
        input: InputDialog = InputDialog(),
        writeOutput: @escaping (String) -> Void = { print($0) },
        writeError: @escaping (String) -> Void = {
            FileHandle.standardError.write(Data(($0 + "\n").utf8))
        },
        performOperation: @escaping (PhotoOperation, InputDialog) async throws -> Void = Self.perform,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        preferredLanguages: [String] = Locale.preferredLanguages
    ) {
        self.input = input
        self.writeOutput = writeOutput
        self.writeError = writeError
        self.performOperation = performOperation
        self.environment = environment
        self.preferredLanguages = preferredLanguages
    }

    func run(arguments: [String]) async -> Int32 {
        var language = CLILanguage.detected(environment: environment, preferredLanguages: preferredLanguages)
        var remaining: [String] = []
        var languageSeen = false
        var languageInvalid = false
        var index = 0
        // Parse every option before producing help/errors, so language selection is independent
        // of its position (including `--help --language ru` and unknown earlier arguments).
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--language" || argument == "--lang" {
                if languageSeen { languageInvalid = true }
                languageSeen = true
                if index + 1 < arguments.count, !arguments[index + 1].hasPrefix("-") {
                    if let selected = CLILanguage(rawValue: arguments[index + 1].lowercased()) {
                        language = selected
                    } else {
                        languageInvalid = true
                    }
                    index += 2
                } else {
                    languageInvalid = true
                    index += 1
                }
            } else {
                remaining.append(argument)
                index += 1
            }
        }
        input.use(language: language)
        let text = input.localization
        if languageInvalid {
            writeError(text(.invalidLanguage))
            return 64
        }
        switch remaining {
        case []: break
        case ["--help"], ["-h"]:
            writeOutput(text(.usage))
            return 0
        case ["--version"]:
            writeOutput("photos-sorter-cli \(BuildVersion.current)")
            return 0
        default:
            writeError(text(.unsupportedArguments))
            return 64
        }

        do {
            while true {
                let text = input.localization
                writeOutput(text(.menu, BuildVersion.current))
                let selection = try input.requestString(text: text(.choice))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if selection == "7" {
                    try selectLanguage()
                    continue
                }
                guard let operation = PhotoOperation(rawValue: selection) else {
                    writeOutput(text(.invalidChoice))
                    continue
                }
                guard operation != .exit else { return 0 }
                try await performOperation(operation, input)
            }
        } catch InputError.endOfInput {
            return 0
        } catch {
            writeError(CoreMessages(text: input.localization).failure(error))
            return 1
        }
    }

    private func selectLanguage() throws {
        while true {
            let text = input.localization
            writeOutput(text(.languageMenu))
            let selection = try input.requestString(text: text(.choice))
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch selection {
            case "0": return
            case "1", "en": input.use(language: .en); return
            case "2", "ru": input.use(language: .ru); return
            default: writeOutput(text(.invalidChoice))
            }
        }
    }

    private static func perform(_ operation: PhotoOperation, input: InputDialog) async throws {
        switch operation {
        case .convertDngToHeic: try await ConvertToHeicScript(inputDialog: input).run(from: .dng)
        case .convertPngToHeic: try await ConvertToHeicScript(inputDialog: input).run(from: .png)
        case .sortPhotos: try await SorterScript(inputDialog: input).run()
        case .fixDate: try await FixDateScript(inputDialog: input).runFixDate()
        case .forceDateSet: try FixDateScript(inputDialog: input).runForceSetDate()
        case .checkValidDateAndName: try await FixDateScript(inputDialog: input).runCheckValidDateAndName()
        case .exit: return
        }
    }
}
