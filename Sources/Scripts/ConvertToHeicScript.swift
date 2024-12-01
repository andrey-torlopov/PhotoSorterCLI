import Foundation
import PhotoSorterCore

/// Unified script for converting various image formats to HEIC
class ConvertToHeicScript {

    private let converter = UnifiedConvertManager()
    private let inputDialog = InputDialog()

    /// Runs the conversion process for the specified source format
    /// - Parameter sourceFormat: The source image format to convert from (e.g., .dng, .png)
    func run(from sourceFormat: SourceFormat) async {
        let formatName = formatDisplayName(for: sourceFormat)
        let folderPath = inputDialog.requestPath(text: "Input path to \(formatName) folder")
        let isDeleteOriginalFiles = inputDialog.requestYesNo(text: "Remove original \(formatName) files?")

        let startDate = CFAbsoluteTimeGetCurrent()
        let folderURL = URL(fileURLWithPath: folderPath)

        await converter.convertToHEIC(
            from: sourceFormat,
            folderURL: folderURL,
            deleteOriginalFile: isDeleteOriginalFiles,
            stateHandler: processStateHandler
        )

        let delta = CFAbsoluteTimeGetCurrent() - startDate
        print(String(format: "Converting finished. Time: %.2f seconds.", delta))
    }

    /// Returns a user-friendly display name for the format
    private func formatDisplayName(for format: SourceFormat) -> String {
        switch format {
        case .dng:
            return "DNG"
        case .png:
            return "PNG"
        }
    }

    /// Handles conversion state updates and displays appropriate messages
    private func processStateHandler(_ state: ConversionState) {
        switch state {
        case .unableToAccessSecurityScopedResource(let folderURL):
            print("❌ Unable to access security-scoped resource: \(folderURL).")
        case .taskCancelled:
            print("❌ Operation cancelled.")
        case .successConvertedAndSaved:
            print("✅ All files were successfully converted and saved.")
        case .fileFoundStartConverting(fileName: let fileName):
            print("⚙️ Processing file: \(fileName).")
        case .originalFileDeleted:
            print("✅ Original file has been deleted.")
        case .cantOpenFolderPath:
            print("❌ Unable to open the specified folder path.")
        case .errorWhenDeletingOriginalFile(text: let text):
            print("❌ An error occurred while deleting the original file: \(text).")
        case .errorReadingFile:
            print("❌ Error reading the file. Please check if the file exists and is accessible.")
        case .errorCreatingCGImage:
            print("❌ Error creating a Core Graphics image. Ensure the file format is supported.")
        case .errorCreatingCGImageDestination:
            print("❌ Error creating a CGImageDestination for saving the HEIC file.")
        case .errorSavingHEICFile:
            print("❌ Error saving the HEIC file. Please check the output path and available storage space.")
        }
    }
}
