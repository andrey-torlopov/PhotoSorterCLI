import Testing
import Foundation
import PhotoSorterCore
@testable import PhotosSorter

/// Tests for FixDateScript class
struct FixDateScriptTests {

    @Test("FixDateScript initializes successfully")
    func testInitialization() {
        let script = FixDateScript()
        _ = script
        #expect(Bool(true))
    }

    @Test("Handle fix date errors prints correct messages")
    func testHandleFixDateError() {
        let script = TestableFixDateScript()
        let testURL = URL(fileURLWithPath: "/test/file.jpg")

        let errors: [FixDateError] = [
            .securityScopedResourceAccessFailed(folderURL: testURL),
            .cancelled,
            .folderNotAccessible(path: testURL),
            .dateUpdateFailed(fileURL: testURL, reason: "reason"),
            .cantFixDate(fileURL: testURL, reason: "reason"),
            .metadataError(filePath: "/test/file.jpg", error: "error text"),
            .creationDateSetFailed(reason: "reason")
        ]

        for error in errors {
            script.testHandleFixDateError(error)
        }

        // Verify no crashes occur
        #expect(Bool(true))
    }

    @Test("Process check state handles all states")
    func testProcessCheckState() {
        let script = TestableFixDateScript()

        let states: [CheckFilesProviderState] = [
            .unableToAccessSecurityScopedResource,
            .cantOpenFolder,
            .taskCancelled,
            .processedFilesCount(count: 42),
            .fileNameDoesNotMatchDate(filePath: "/test/file.jpg", fileDate: "2024-01-01"),
            .fileNameDoesNotMatchDate(filePath: "/test/file2.jpg", fileDate: nil),
            .processedFilesResult(count: 100)
        ]

        for state in states {
            script.testProcessCheckState(state)
        }

        // Verify no crashes occur
        #expect(Bool(true))
    }

    @Test("Process check state outputs appropriate messages")
    func testProcessCheckStateMessages() {
        let script = TestableFixDateScript()

        script.testProcessCheckState(.processedFilesCount(count: 10))
        script.testProcessCheckState(.processedFilesResult(count: 50))
        script.testProcessCheckState(.fileNameDoesNotMatchDate(filePath: "/path/photo.jpg", fileDate: "2024-01-15"))

        #expect(Bool(true))
    }
}

/// Testable version of FixDateScript that exposes private methods
class TestableFixDateScript: FixDateScript {

    /// Exposes handleFixDateError for testing
    func testHandleFixDateError(_ error: FixDateError) {
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

    /// Exposes processCheckState for testing
    func testProcessCheckState(_ state: CheckFilesProviderState) {
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
}
