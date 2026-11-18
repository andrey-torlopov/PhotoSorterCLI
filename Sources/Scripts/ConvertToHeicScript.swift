import Foundation
import PhotoSorterCore

/// Terminal setup and presentation only; the conversion algorithm stays in Core.
final class ConvertToHeicScript {
    private let converter = UnifiedConvertManager()
    private let inputDialog: InputDialog

    init(inputDialog: InputDialog = InputDialog()) { self.inputDialog = inputDialog }

    func run(from sourceFormat: SourceFormat) async throws {
        let text = inputDialog.localization
        let formatName = sourceFormat == .dng ? "DNG" : "PNG"
        let folderPath = try inputDialog.requestPath(text: text(.conversionFolder, formatName))
        let deleteOriginals = try inputDialog.requestYesNo(text: text(.conversionDelete, formatName), defaultYes: false)
        let started = CFAbsoluteTimeGetCurrent()
        await converter.convertToHEIC(
            from: sourceFormat,
            folderURL: URL(fileURLWithPath: folderPath),
            deleteOriginalFile: deleteOriginals,
            stateHandler: { self.inputDialog.writeLine(CoreMessages(text: text).conversion($0)) }
        )
        inputDialog.writeLine(text(.conversionFinished, CFAbsoluteTimeGetCurrent() - started))
    }
}
