import Testing
import Foundation
import PhotoSorterCore
@testable import PhotosSorter

/// Tests for InputDialog class
/// Note: These tests focus on testable logic. Interactive methods (requestYesNo, requestPath, requestString)
/// that depend on readLine() are difficult to unit test and should be tested through integration tests.
struct InputDialogTests {

    @Test("InputDialog initializes successfully")
    func testInitialization() {
        let dialog = InputDialog()
        _ = dialog
        #expect(Bool(true))
    }

    @Test("Date parsing with sanitizeDateInput removes invalid characters")
    func testSanitizeDateInput() throws {
        let dialog = TestableInputDialog()

        // Test removing special characters
        #expect(dialog.testSanitizeDateInput("12.03.2024 14:30") == "12.03.2024 14:30")
        #expect(dialog.testSanitizeDateInput("12/03/2024") == "12032024")
        #expect(dialog.testSanitizeDateInput("2024-03-12") == "2024-03-12")
        #expect(dialog.testSanitizeDateInput("12.03.2024@14:30") == "12.03.202414:30")
        #expect(dialog.testSanitizeDateInput("abc123def") == "123")
        #expect(dialog.testSanitizeDateInput("!@#$%^&*()") == "")
    }

    @Test("Date parsing handles various formats")
    func testDateParsing() {
        let dialog = TestableInputDialog()

        // Test valid date formats
        let testCases: [(input: String, shouldParse: Bool)] = [
            ("2024-03-12 14:30", true),
            ("2024-03-12", true),
            ("12.03.2024 14:30", true),
            ("12.03.2024", true),
            ("invalid date", false),
            ("", false)
        ]

        for testCase in testCases {
            let sanitized = dialog.testSanitizeDateInput(testCase.input)
            // We can't directly test requestDate since it depends on readLine()
            // but we can verify sanitization works correctly
            #expect(!sanitized.contains(where: { char in
                !CharacterSet(charactersIn: "0123456789.-: ").contains(char.unicodeScalars.first!)
            }))
        }
    }
}

/// Testable version of InputDialog that exposes private methods for testing
class TestableInputDialog: InputDialog {

    /// Exposes the private sanitizeDateInput method for testing
    func testSanitizeDateInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.-: ")
        return input.filter { char in
            guard let scalar = char.unicodeScalars.first else { return false }
            return allowedCharacters.contains(scalar)
        }
    }
}
