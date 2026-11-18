import Foundation
import PhotoSorterCore

final class FixDateScript {
    private let inputDialog: InputDialog
    private let fixDateTool = FixDateTool(commandExecutor: CLICommandExecutor())
    private let checkFilesProvider = CheckFilesProvider()

    init(inputDialog: InputDialog = InputDialog()) { self.inputDialog = inputDialog }

    func runFixDate() async throws {
        let text = inputDialog.localization
        let inputFolder = try inputDialog.requestPath(text: text(.folderPrompt))
        let started = CFAbsoluteTimeGetCurrent()
        do {
            try fixDateTool.fixDatesIn(folderURL: URL(fileURLWithPath: inputFolder)) {
                self.inputDialog.writeLine(CoreMessages(text: text).fixDate($0))
            }
            inputDialog.writeLine(text(.dateFinished, CFAbsoluteTimeGetCurrent() - started))
        } catch {
            inputDialog.writeLine(CoreMessages(text: text).failure(error))
        }
    }

    func runForceSetDate() throws {
        let text = inputDialog.localization
        let inputPath = try inputDialog.requestPath(text: text(.folderPrompt))
        let inputDate = try inputDialog.requestDate(text: text(.forceDatePrompt))
        let started = CFAbsoluteTimeGetCurrent()
        do {
            try fixDateTool.forceSetDate(with: inputDate, forFolder: URL(fileURLWithPath: inputPath)) {
                self.inputDialog.writeLine(CoreMessages(text: text).fixDate($0))
            }
            inputDialog.writeLine(text(.dateFinished, CFAbsoluteTimeGetCurrent() - started))
        } catch {
            inputDialog.writeLine(CoreMessages(text: text).failure(error))
        }
    }

    func runCheckValidDateAndName() async throws {
        let text = inputDialog.localization
        let inputPath = try inputDialog.requestPath(text: text(.folderPrompt))
        await checkFilesProvider.checkFiles(in: URL(fileURLWithPath: inputPath)) {
            self.inputDialog.writeLine(CoreMessages(text: text).check($0))
        }
    }
}
