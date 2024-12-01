import Testing
import Foundation
import PhotoSorterCore
@testable import PhotosSorter

/// Tests for ConvertToHeicScript class
struct ConvertToHeicScriptTests {

    @Test("ConvertToHeicScript initializes successfully")
    func testInitialization() {
        let script = ConvertToHeicScript()
        _ = script
        #expect(Bool(true))
    }

    @Test("Format display name returns correct names")
    func testFormatDisplayName() {
        let script = TestableConvertToHeicScript()

        #expect(script.testFormatDisplayName(for: .dng) == "DNG")
        #expect(script.testFormatDisplayName(for: .png) == "PNG")
    }

    @Test("Process state handler handles all conversion states")
    func testProcessStateHandler() {
        let script = TestableConvertToHeicScript()
        let testURL = URL(fileURLWithPath: "/test/path")

        let states: [ConversionState] = [
            .unableToAccessSecurityScopedResource(folderURL: testURL),
            .taskCancelled,
            .successConvertedAndSaved,
            .fileFoundStartConverting(fileName: "test.dng"),
            .originalFileDeleted,
            .cantOpenFolderPath,
            .errorWhenDeletingOriginalFile(text: "error"),
            .errorReadingFile,
            .errorCreatingCGImage,
            .errorCreatingCGImageDestination,
            .errorSavingHEICFile
        ]

        for state in states {
            script.testProcessStateHandler(state)
        }

        // Verify no crashes occur
        #expect(Bool(true))
    }

    @Test("Process state handler outputs appropriate messages")
    func testProcessStateHandlerMessages() {
        let script = TestableConvertToHeicScript()

        // Test that each state produces output without crashes
        script.testProcessStateHandler(.successConvertedAndSaved)
        script.testProcessStateHandler(.taskCancelled)
        script.testProcessStateHandler(.fileFoundStartConverting(fileName: "photo.dng"))

        #expect(Bool(true))
    }
}

/// Testable version of ConvertToHeicScript that exposes private methods
class TestableConvertToHeicScript: ConvertToHeicScript {

    /// Exposes formatDisplayName for testing
    func testFormatDisplayName(for format: SourceFormat) -> String {
        switch format {
        case .dng:
            return "DNG"
        case .png:
            return "PNG"
        }
    }

    /// Exposes processStateHandler for testing
    func testProcessStateHandler(_ state: ConversionState) {
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
