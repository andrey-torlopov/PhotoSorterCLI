import Foundation
import PhotoSorterCore
import Testing
@testable import PhotosSorter

struct LocalizationTests {
    @Test("Menu language changes immediately in menus and the next file operation")
    func menuLanguageSwitching() async {
        let terminal = TerminalFixture(["7", "2", "1", "7", "1", "2", "0"])
        var output = ""
        var operationLanguages: [CLILanguage] = []
        var operationPrompts: [String] = []
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { output += $0 + "\n" },
                                 writeError: { _ in }, performOperation: { _, input in
            operationLanguages.append(input.localization.language)
            operationPrompts.append(input.localization(.conversionDelete, "DNG"))
        })
        #expect(await app.run(arguments: ["--language", "en"]) == 0)
        #expect(operationLanguages == [.ru, .en])
        #expect(operationPrompts == ["Удалить исходные файлы DNG?", "Remove original DNG files?"])
        #expect(output.contains("Выберите команду"))
        #expect(output.contains("7. Язык / Language"))
        #expect(output.contains("7. Language / Язык"))
    }

    @Test("Language menu retries invalid input and Back preserves the current language")
    func languageMenuBackAndInvalidInput() async {
        let terminal = TerminalFixture(["7", "invalid", "0", "1", "0"])
        var output = ""
        var operationLanguages: [CLILanguage] = []
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { output += $0 },
                                 writeError: { _ in }, performOperation: { _, input in
            operationLanguages.append(input.localization.language)
        })
        #expect(await app.run(arguments: ["--language", "ru"]) == 0)
        #expect(operationLanguages == [.ru])
        #expect(output.contains("Недопустимый ввод"))
    }

    @Test("EOF in language selection exits without file operations")
    func languageMenuEOF() async {
        let terminal = TerminalFixture(["7"])
        var operations = 0
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { _ in },
                                 performOperation: { _, _ in operations += 1 })
        #expect(await app.run(arguments: []) == 0)
        #expect(operations == 0)
        #expect(terminal.readCount == 2)
    }

    @Test("An operation failure uses the language selected in the menu")
    func languageMenuFailure() async {
        let terminal = TerminalFixture(["7", "ru", "1"])
        var errorOutput = ""
        let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { errorOutput += $0 },
                                 performOperation: { _, _ in throw SorterError.permissionDenied })
        #expect(await app.run(arguments: ["--language", "en"]) == 1)
        #expect(errorOutput.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil)
        #expect(!errorOutput.contains("Permission denied"))
    }

    @Test("POSIX locale precedence, unsupported locale and system fallback are deterministic")
    func localeDetection() {
        #expect(CLILanguage.detected(environment: ["LC_ALL": "ru_RU.UTF-8", "LC_MESSAGES": "en_US", "LANG": "en_US"], preferredLanguages: ["en"]) == .ru)
        #expect(CLILanguage.detected(environment: ["LC_ALL": "", "LC_MESSAGES": "en_US.UTF-8", "LANG": "ru_RU"], preferredLanguages: ["ru"]) == .en)
        #expect(CLILanguage.detected(environment: ["LANG": "ru-RU"], preferredLanguages: ["en"]) == .ru)
        for locale in ["C", "POSIX", "C.UTF-8", "fr_FR.UTF-8"] {
            #expect(CLILanguage.detected(environment: ["LC_ALL": locale, "LANG": "ru_RU"], preferredLanguages: ["ru"]) == .en)
        }
        #expect(CLILanguage.detected(environment: [:], preferredLanguages: ["fr-FR", "ru-RU", "en-US"]) == .ru)
        #expect(CLILanguage.detected(environment: [:], preferredLanguages: ["fr-FR"]) == .en)
    }

    @Test("Language flag overrides environment before help regardless of argument order")
    func explicitLanguage() async {
        for arguments in [["--language", "ru", "--help"], ["--help", "--language", "ru"], ["-h", "--lang", "ru"]] {
            let terminal = TerminalFixture()
            var output = ""
            let app = CLIApplication(input: terminal.dialog(), writeOutput: { output += $0 }, writeError: { _ in },
                                     environment: ["LC_ALL": "en_US"], preferredLanguages: ["en"])
            #expect(await app.run(arguments: arguments) == 0)
            #expect(output.contains("Использование:"))
            #expect(terminal.readCount == 0)
        }
    }

    @Test("Invalid language flags never open the menu; errors use explicit or detected language")
    func invalidLanguageArguments() async {
        for arguments in [["--language"], ["--language", "de"], ["--language", "ru", "--lang", "en"], ["--language", "--help"]] {
            let terminal = TerminalFixture()
            var errors = ""
            let app = CLIApplication(input: terminal.dialog(), writeOutput: { _ in }, writeError: { errors += $0 },
                                     environment: ["LANG": "ru_RU"], preferredLanguages: ["en"])
            #expect(await app.run(arguments: arguments) == 64)
            #expect(errors.contains("--language ru"))
            #expect(terminal.readCount == 0)
        }
        var errors = ""
        let app = CLIApplication(writeError: { errors += $0 }, environment: ["LANG": "en_US"], preferredLanguages: ["en"])
        #expect(await app.run(arguments: ["--unknown", "--language", "ru"]) == 64)
        #expect(errors.contains("Недопустимые аргументы"))
    }

    @Test("Russian and English confirmations work in both languages, including safe empty input")
    func bilingualAnswers() throws {
        for language in CLILanguage.allCases {
            for answer in ["да", "Д", " Да ", "y", "YES"] {
                let dialog = TerminalFixture([answer]).dialog()
                dialog.use(language: language)
                #expect(try dialog.requestYesNo(text: "?", defaultYes: false))
            }
            for answer in ["нет", "Н", " Нет ", "n", "NO", ""] {
                let dialog = TerminalFixture([answer]).dialog()
                dialog.use(language: language)
                #expect(try dialog.requestYesNo(text: "?", defaultYes: false) == false)
            }
            let terminal = TerminalFixture(["maybe", ""])
            let dialog = terminal.dialog()
            dialog.use(language: language)
            #expect(try dialog.requestYesNo(text: "?", defaultYes: false) == false)
            #expect(terminal.output.contains(language == .ru ? "Недопустимый ответ" : "Invalid input"))
        }
    }

    @Test("Russian setup preserves original paths, date format input and keep-original configuration")
    func russianConfiguration() throws {
        let terminal = TerminalFixture(["/Фото input", "/Фото output", "да", "нет", "да", "нет", "", "да"])
        let dialog = terminal.dialog()
        dialog.use(language: .ru)
        let candidate = try SorterScript(inputDialog: dialog).prepareInputParameters()
        let configuration = try #require(candidate)
        #expect(configuration.disposition == .keepOriginal)
        #expect(configuration.inputFolder.path == "/Фото input")
        #expect(terminal.output.contains("Удалить оригиналы после обработки: НЕТ"))
        let dates = TerminalFixture(["day=12 month=03 year=2024", "'day='dd 'month='MM 'year='yyyy"])
        let dateDialog = dates.dialog()
        dateDialog.use(language: .ru)
        let date = try dateDialog.requestDate(text: "Дата")
        #expect(Calendar.current.component(.month, from: date) == 3)
        #expect(dates.output.contains("Введите формат даты"))
    }

    @Test("Every embedded message has both translations and matching format arguments")
    func catalogueCompleteness() {
        for message in CLIMessage.allCases {
            let translations = message.translations
            #expect(!translations.en.isEmpty && !translations.ru.isEmpty)
            #expect(translations.ru.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil)
            func placeholders(_ value: String) -> [String] {
                value.matches(of: /%(?:\.[0-9]+)?(?:ld|[@df])/).map { String($0.output) }
            }
            #expect(placeholders(translations.en) == placeholders(translations.ru))
        }
    }

    @Test("System command adapter keeps exit status and suppresses unlocalized subprocess output")
    func subprocessStatus() {
        let executor = CLICommandExecutor()
        let shell = URL(fileURLWithPath: "/bin/sh")
        #expect(executor.execute(executable: shell, arguments: ["-c", "printf RAW_SUBPROCESS_OUTPUT_MUST_NOT_ESCAPE; printf RAW_SUBPROCESS_ERROR_MUST_NOT_ESCAPE >&2; exit 0"]))
        #expect(!executor.execute(executable: shell, arguments: ["-c", "printf RAW_SUBPROCESS_ERROR_MUST_NOT_ESCAPE >&2; exit 7"]))
        #expect(!executor.execute(executable: URL(fileURLWithPath: "/nonexistent-cli-test-command"), arguments: []))
    }

    @Test("Counters and NSError codes preserve 64-bit Swift Int values")
    func largeIntegerFormatting() {
        let large = Int(Int32.max) + 42
        for language in CLILanguage.allCases {
            let text = CLILocalization(language: language)
            #expect(text(.processedTotal, large).filter { !$0.isWhitespace }.contains(String(large)))
            let error = NSError(domain: NSCocoaErrorDomain, code: large)
            #expect(CoreMessages(text: text).failure(error).contains(String(large)))
        }
    }

    @Test("Typed Core diagnostics preserve paths and never leak opaque descriptions")
    func typedCoreDiagnostics() {
        let raw = "OPAQUE_ENGLISH_ERROR_SHOULD_NOT_LEAK"
        let url = URL(fileURLWithPath: "/tmp/Фото оригинал.png")
        for language in CLILanguage.allCases {
            let formatter = CoreMessages(text: CLILocalization(language: language))
            let conversion: [ConversionState] = [.unableToAccessSecurityScopedResource(folderURL: url), .taskCancelled,
                .successConvertedAndSaved, .fileFoundStartConverting(fileName: url.path), .originalFileDeleted,
                .cantOpenFolderPath, .errorWhenDeletingOriginalFile(text: raw), .errorReadingFile,
                .errorCreatingCGImage, .errorCreatingCGImageDestination, .errorSavingHEICFile]
            let fixes: [FixDateError] = [.securityScopedResourceAccessFailed(folderURL: url), .cancelled,
                .folderNotAccessible(path: url), .dateUpdateFailed(fileURL: url, reason: raw),
                .cantFixDate(fileURL: url, reason: raw), .metadataError(filePath: url.path, error: raw),
                .creationDateSetFailed(reason: raw)]
            let files: [FileProcessingError] = [.invalidDate(filePath: url.path, dateString: "2024-99-99"),
                .missingDateComponents(filePath: url.path), .moveFailed(source: url.path, destination: "/output", reason: raw),
                .copyFailed(source: url.path, destination: "/output", reason: raw), .dateUpdateFailed(fileURL: url, reason: raw),
                .cantFixDate(fileURL: url, reason: raw), .metadataError(filePath: url.path, error: raw),
                .creationDateSetFailed(filePath: url.path, reason: raw)]
            let checks: [CheckFilesProviderState] = [.unableToAccessSecurityScopedResource, .cantOpenFolder, .taskCancelled,
                .processedFilesCount(count: 3), .fileNameDoesNotMatchDate(filePath: url.path, fileDate: nil), .processedFilesResult(count: 3)]
            let progress: [SorterProgress] = [.started, .folderCreated(name: "/output"),
                .fileProcessed(sourcePath: url.path, targetPath: "/output/photo.png"), .fileSkipped(path: url.path), .completed(processedCount: 3)]
            let failures: [Error] = [SorterError.permissionDenied, SorterError.folderNotAccessible(path: url.path),
                SorterError.folderCreationFailed(path: url.path), SorterError.cancelled, fixes[3], files[3],
                NSError(domain: NSCocoaErrorDomain, code: 257, userInfo: [NSLocalizedDescriptionKey: raw])]
            let messages = conversion.map(formatter.conversion) + fixes.map(formatter.fixDate) + files.map(formatter.fileError)
                + checks.map(formatter.check) + progress.map(formatter.progress) + failures.map(formatter.failure)
            for message in messages {
                #expect(!message.contains(raw))
                #expect(!message.isEmpty)
                if language == .ru { #expect(message.range(of: "[А-Яа-яЁё]", options: .regularExpression) != nil) }
            }
            #expect(formatter.fileError(files[3]).contains(url.path))
            #expect(formatter.failure(failures[6]).contains("257"))
        }
    }
}
