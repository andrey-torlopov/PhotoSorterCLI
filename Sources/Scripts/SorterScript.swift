import Foundation
import PhotoSorterCore

/// Configures Core's sorting operation and renders typed progress in the chosen language.
final class SorterScript {
    private let inputDialog: InputDialog
    private var text: CLILocalization { inputDialog.localization }

    init(inputDialog: InputDialog = InputDialog()) { self.inputDialog = inputDialog }

    func run() async throws {
        guard let configuration = try prepareInputParameters() else { return }
        let started = CFAbsoluteTimeGetCurrent()
        do {
            let result = try await SorterEngine(configure: configuration, fixDateTool: FixDateTool(commandExecutor: CLICommandExecutor())).run(
                progressHandler: { self.inputDialog.writeLine(CoreMessages(text: self.text).progress($0)) },
                errorHandler: { self.inputDialog.writeLine(CoreMessages(text: self.text).fileError($0)) }
            )
            inputDialog.writeLine(text(.sortingFinished, CFAbsoluteTimeGetCurrent() - started))
            inputDialog.writeLine(text(.processedTotal, result.processedCount))
            inputDialog.writeLine(text(.errorsTotal, result.errors.count))
        } catch {
            inputDialog.writeLine(CoreMessages(text: text).failure(error))
        }
    }

    func prepareInputParameters() throws -> SorterEngine.Configure? {
        while true {
            let input = try inputDialog.requestPath(text: text(.sourceFolderPrompt))
            let output = try inputDialog.requestPath(text: text(.destinationFolderPrompt))
            let rename = try inputDialog.requestYesNo(text: text(.renamePrompt))
            inputDialog.writeLine(text(.dateExplanation))
            let fixMetadata = try inputDialog.requestYesNo(text: text(.fixMetadataPrompt), defaultYes: false)
            inputDialog.writeLine(text(.foldersExplanation))
            let createFolders = try inputDialog.requestYesNo(text: text(.createFoldersPrompt))
            let customDate = try requestCustomDate(fixMetadata: fixMetadata)
            let deleteOriginals = try inputDialog.requestYesNo(text: text(.deletePrompt), defaultYes: false)

            inputDialog.writeLine("---")
            inputDialog.writeLine(text(.confirmSettings))
            inputDialog.writeLine(text(.sourceFolderSetting, input))
            inputDialog.writeLine(text(.destinationFolderSetting, output))
            setting(.renameSetting, enabled: rename)
            setting(.fixMetadataSetting, enabled: fixMetadata)
            setting(.foldersSetting, enabled: createFolders)
            setting(.deleteSetting, enabled: deleteOriginals)
            setting(.forceDateSetting, enabled: customDate != nil)
            inputDialog.writeLine(text(.customDateSetting, customDate.map(text.date) ?? text(.notSet)))
            inputDialog.writeLine("---")
            guard try inputDialog.requestYesNo(text: text(.startPrompt)) else { continue }

            var options: SorterEngine.Options = []
            if rename { options.insert(.renameFiles) }
            if fixMetadata { options.insert(.fixMetadata) }
            if createFolders { options.insert(.createFolders) }
            return SorterEngine.Configure.builder(input: URL(fileURLWithPath: input), output: URL(fileURLWithPath: output))
                .options(options)
                .disposition(deleteOriginals ? .move : .keepOriginal)
                .concreteDate(customDate)
                .build()
        }
    }

    private func setting(_ message: CLIMessage, enabled: Bool) {
        inputDialog.writeLine("\(enabled ? "✅" : "🔴") \(text(message, text(enabled ? .yes : .no)))")
    }

    private func requestCustomDate(fixMetadata: Bool) throws -> Date? {
        guard !fixMetadata else {
            inputDialog.writeLine(text(.customDateSkippedMetadata))
            return nil
        }
        while true {
            guard try inputDialog.requestYesNo(text: text(.customDatePrompt), defaultYes: false) else {
                inputDialog.writeLine(text(.customDateSkipped))
                return nil
            }
            let date = try inputDialog.requestDate(text: text(.customDateInput))
            inputDialog.writeLine(text(.dateEntered, text.date(date)))
            if try inputDialog.requestYesNo(text: text(.confirmDatePrompt)) {
                inputDialog.writeLine(text(.dateConfirmed, text.date(date)))
                return date
            }
            inputDialog.writeLine(text(.dateRejected))
        }
    }
}
