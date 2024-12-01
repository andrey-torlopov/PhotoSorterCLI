import Foundation
import PhotoSorterCore

/// Fixing file dates.
class FixDateScript {

    let fixDateTool = FixDateTool()
    let checkFilesProvider = CheckFilesProvider()

    func runFixDate() async {
        let inputFolder = InputDialog().requestPath(text: "Enter the folder path")
        let startDate = CFAbsoluteTimeGetCurrent()
        let folderURL = URL(fileURLWithPath: inputFolder)

        do {
            try fixDateTool.fixDatesIn(folderURL: folderURL, errorHandler: { error in
                self.handleFixDateError(error)
            })
            let delta = CFAbsoluteTimeGetCurrent() - startDate
            print(String(format: "✅ Date fixing completed. Time: %.2f seconds.", delta))
        } catch {
            print("🔴 Critical error: \(error)")
        }
    }

    func runForceSetDate() {
        let inputPath = InputDialog().requestPath(text: "Enter the folder path")
        let folderURL = URL(fileURLWithPath: inputPath)
        let inputDate = InputDialog().requestDate(text: "Enter the date you want to set for the files")
        let startDate = CFAbsoluteTimeGetCurrent()

        do {
            try fixDateTool.forceSetDate(with: inputDate, forFolder: folderURL, errorHandler: { error in
                self.handleFixDateError(error)
            })
            let delta = CFAbsoluteTimeGetCurrent() - startDate
            print(String(format: "✅ Date fixing completed. Time: %.2f seconds.", delta))
        } catch {
            print("🔴 Critical error: \(error)")
        }
    }

    func runCheckValidDateAndName() async {
        let inputPath = InputDialog().requestPath(text: "Enter the folder path")
        let folderURL = URL(fileURLWithPath: inputPath)
        await checkFilesProvider.checkFiles(in: folderURL, stateHandler: processCheckState)
    }

    private func processCheckState(_ state: CheckFilesProviderState) {
        switch state {
        case .unableToAccessSecurityScopedResource:
            print("❌ Unable to access security-scoped resource.")
        case .cantOpenFolder:
            print("❌ Could not open the folder.")
        case .taskCancelled:
            print("...Task cancelled.")
        case .processedFilesCount(let count):
            print("📊 Files processed so far: \(count)")
        case .fileNameDoesNotMatchDate(let filePath, let fileDate):
            print("❌ File name does not match date for file \(filePath). Expected date: \(fileDate ?? "no date")")
        case .processedFilesResult(let count):
            print("✅ All files processed. Total files: \(count)")
        }
    }

    private func handleFixDateError(_ error: FixDateError) {
        switch error {
        case .securityScopedResourceAccessFailed:
            print("❌ Unable to access security-scoped resource")
        case .cancelled:
            print("...Task cancelled")
        case .folderNotAccessible(let path):
            print("❌ Could not open folder at path: \(path)")
        case .dateUpdateFailed(let fileURL, let reason):
            print("❌ Failed to update date for \(fileURL.path): \(reason)")
        case .cantFixDate(let fileURL, let reason):
            print("❌ Unable to fix date for \(fileURL.path): \(reason)")
        case .metadataError(let filePath, let errorText):
            print("❌ Metadata error for \(filePath): \(errorText)")
        case .creationDateSetFailed(let reason):
            print("❌ Creation date set failed: \(reason)")
        }
    }
}
