import Foundation
import PhotoSorterCore

/// A script to sort and process files based on user-defined settings.
class SorterScript {

    /// Runs the sorting process by preparing input parameters and executing the sorter engine.
    func run() async {
        if let configure: SorterEngine.Configure = prepeareInputparameters() {
            let startDate = CFAbsoluteTimeGetCurrent()
            let sorterEngine = SorterEngine(configure: configure)

            do {
                let result = try await sorterEngine.run(
                    progressHandler: { progress in
                        self.handleProgress(progress)
                    },
                    errorHandler: { error in
                        self.handleError(error)
                    }
                )

                let delta = CFAbsoluteTimeGetCurrent() - startDate
                print(String(format: "🏁 Sorting completed. Time elapsed: %.2f seconds.", delta))
                print("📊 Total files processed: \(result.processedCount)")
                print("❌ Total errors: \(result.errors.count)")
            } catch {
                print("🔴 Critical error: \(error)")
            }
        } else {
            print("🔴 Something went wrong!")
        }
    }

    /// Prepares the input parameters by prompting the user for necessary information.
    /// - Returns: A `SorterEngine.Configure` instance if the user confirms, or `nil` if the process is canceled.
    func prepeareInputparameters() -> SorterEngine.Configure? {
        while true {
            // Collect basic parameters
            let inputFolder = requestFolderPath(prompt: "Enter the source folder path (folder must exist):")
            let outputFolder = requestFolderPath(prompt: "Enter the destination folder path (folder must exist):")
            let isRenameFileWithDateFormat = InputDialog().requestYesNo(
                text: "Rename files to date format (e.g., 2024-01-02--12-31)? (Recommended)"
            )

            // Metadata and folder structure preferences
            print("ℹ️ You can either automatically fix creation/modification dates or specify a custom date manually.")
            let isFixMetadata = InputDialog().requestYesNo(
                text: "Fix file metadata based on content creation date? (Recommended)",
                defaultYes: false
            )
            print("ℹ️ You can choose whether to create a folder hierarchy (Year-Month) and separate photos/videos.")
            let isMakeFolderStructure = InputDialog().requestYesNo(
                text: "Create a folder structure in the destination folder? (Recommended)"
            )

            // Request custom date if needed
            let (isForceUpdateDate, customDate) = getCustomDate(isFixMetadata: isFixMetadata)

            // Final option to remove original files
            let isRemoveOriginalFile = InputDialog().requestYesNo(
                text: "Remove original files after processing?",
                defaultYes: true
            )

            // Confirm and validate settings
            if confirmSettings(
                inputFolder: inputFolder,
                outputFolder: outputFolder,
                isRenameFileWithDateFormat: isRenameFileWithDateFormat,
                isFixMetadata: isFixMetadata,
                isMakeFolderStructure: isMakeFolderStructure,
                isForceUpdateDate: isForceUpdateDate,
                customDate: customDate,
                isRemoveOriginalFile: isRemoveOriginalFile
            ) {
                // Build options based on user settings.
                // В Core 0.0.4 опции .forceUpdateDate и .deleteOriginals удалены:
                // - форсирование конкретной даты теперь задаётся через .concreteDate
                //   (наличие даты включает форс и переопределяет .fixMetadata),
                // - move/copy оригиналов - через .disposition (.move / .keepOriginal).
                var options: SorterEngine.Options = []
                if isRenameFileWithDateFormat { options.insert(.renameFiles) }
                if isFixMetadata { options.insert(.fixMetadata) }
                if isMakeFolderStructure { options.insert(.createFolders) }

                // Use the new builder API
                return SorterEngine.Configure.builder(
                    input: URL(fileURLWithPath: inputFolder),
                    output: URL(fileURLWithPath: outputFolder)
                )
                .options(options)
                .disposition(isRemoveOriginalFile ? .move : .keepOriginal)
                .concreteDate(customDate)
                .build()
            }
        }
    }

    /// Prompts the user to enter a folder path with a specific message.
    /// - Parameter prompt: The text to display in the dialog.
    /// - Returns: The folder path entered by the user.
    private func requestFolderPath(prompt: String) -> String {
        InputDialog().requestPath(text: prompt)
    }

    /// Displays a confirmation dialog summarizing the settings.
    /// - Parameters: Various configuration options to summarize.
    /// - Returns: `true` if the user confirms the settings, `false` otherwise.
    private func confirmSettings(
        inputFolder: String,
        outputFolder: String,
        isRenameFileWithDateFormat: Bool,
        isFixMetadata: Bool,
        isMakeFolderStructure: Bool,
        isForceUpdateDate: Bool,
        customDate: Date?,
        isRemoveOriginalFile: Bool
    ) -> Bool {
        print("---\n\n")
        print("Confirm the following settings:")
        print("✅ Source folder: \(inputFolder)")
        print("✅ Destination folder: \(outputFolder)")
        print("\(isRenameFileWithDateFormat ? "✅" : "🔴") Rename files to date format: \(isRenameFileWithDateFormat ? "YES" : "NO")")
        print("\(isFixMetadata ? "✅" : "🔴") Fix metadata (creation/modification dates): \(isFixMetadata ? "YES" : "NO")")
        print("\(isMakeFolderStructure ? "✅" : "🔴") Create folder structure in destination: \(isMakeFolderStructure ? "YES" : "NO")")
        print("\(isRemoveOriginalFile ? "✅" : "🔴") Remove original files after processing: \(isRemoveOriginalFile ? "YES" : "NO")")
        print("\(isForceUpdateDate ? "✅" : "🔴") Force custom date: \(isForceUpdateDate ? "YES" : "NO")")
        print("\(customDate != nil ? "✅" : "🔴") Custom date: \(customDate?.description ?? "Not set")")
        print("---\n\n")

        return InputDialog().requestYesNo(text: "Start with these settings?")
    }

    /// Prompts the user to specify a custom date for sorting files, if applicable.
    /// - Parameter isFixMetadata: A flag indicating whether metadata should be fixed. If `true`, the method returns default values.
    /// - Returns: A tuple containing a flag indicating if a custom date is forced and the custom date itself.
    private func getCustomDate(isFixMetadata: Bool) -> (isForceUpdate: Bool, customDate: Date?) {
        guard !isFixMetadata else {
            print("❌ Metadata fixing is enabled. Skipping custom date selection.")
            return (false, nil)
        }

        while true {
            let isSetCustomDate = InputDialog().requestYesNo(
                text: "Would you like to set a custom creation/modification date for all files?",
                defaultYes: false
            )

            if !isSetCustomDate {
                print("ℹ️ Custom date selection was skipped.")
                break
            }

            let date = InputDialog().requestDate(
                text: "Please specify the date in the format dd.MM.yyyy HH:mm: "
            )

            print("You entered the date: \(date)")
            let isCorrect = InputDialog().requestYesNo(
                text: "Do you confirm this date?",
                defaultYes: true
            )

            if isCorrect {
                print("✅ Custom date confirmed: \(date).")
                return (true, date)
            } else {
                print("❌ Custom date entry was rejected. Prompting again...")
            }
        }

        return (false, nil)
    }

    /// Handles progress updates from the sorter engine
    private func handleProgress(_ progress: SorterProgress) {
        switch progress {
        case .started:
            print("🚀 Sorting started...")
        case .folderCreated(let name):
            print("📂 Folder created: \(name)")
        case .fileProcessed(let sourcePath, let targetPath):
            print("✅ File processed: \(sourcePath) → \(targetPath)")
        case .fileSkipped(let path):
            print("⏭️ File skipped (already dated): \(path)")
        case .completed(let count):
            print("🏁 Sorting completed. Files processed: \(count)")
        }
    }

    /// Handles errors from the sorter engine
    private func handleError(_ error: FileProcessingError) {
        switch error {
        case .invalidDate(let filePath, let dateString):
            print("❌ Invalid date in file: \(filePath) - \(dateString)")
        case .missingDateComponents(let filePath):
            print("❌ Missing date components: \(filePath)")
        case .moveFailed(let source, let destination, let reason):
            print("❌ Move failed: \(source) → \(destination): \(reason)")
        case .copyFailed(let source, let destination, let reason):
            print("❌ Copy failed: \(source) → \(destination): \(reason)")
        case .dateUpdateFailed(let fileURL, let reason):
            print("❌ Date update failed: \(fileURL.path): \(reason)")
        case .cantFixDate(let fileURL, let reason):
            print("❌ Can't fix date: \(fileURL.path): \(reason)")
        case .metadataError(let filePath, let error):
            print("❌ Metadata error: \(filePath): \(error)")
        case .creationDateSetFailed(let filePath, let reason):
            print("❌ Creation date set failed: \(filePath): \(reason)")
        }
    }
}
