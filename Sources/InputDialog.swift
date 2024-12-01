import Foundation
import PhotoSorterCore

/// Input dialogs for console interface
class InputDialog {
    private let dateFormattingService = DateFormattingService.shared

    init() {}

    func requestYesNo(text: String, defaultYes: Bool = true) -> Bool {
        while true {
            print("\(text) \(defaultYes ?"(Y/n)" : "(y/N)"):", terminator: "")
            if let input = readLine(strippingNewline: true)?.lowercased() {
                if input == "y" || (input.isEmpty && defaultYes) {
                    return true
                } else if input == "n" || (input.isEmpty && !defaultYes) {
                    return false
                } else {
                    print("Invalid input. Please enter Y or n.")
                }
            } else {
                print("Input error. Please try again.")
            }
        }
    }

    func requestPath(text: String) -> String {
        while true {
            print("\(text): ", terminator: "")
            if let inputPath = readLine(strippingNewline: true) {
                let inputURL = URL(fileURLWithPath: inputPath)
                if PathValidator.validate(inputURL) {
                    return inputPath
                } else {
                    print("Invalid path. Please try again.")
                }
            } else {
                print("Input error. Please try again.")
            }
        }
    }

    func requestDate(text: String) -> Date {
        let predefinedFormats: [DateFormattingService.Format] = [
            .yyyyMMddHHmm, .yyyyMMdd, .ddMMyyyyHHmm, .ddMMyyyy
        ]

        while true {
            print("\(text): ", terminator: "")
            if let inputStringDate = readLine(strippingNewline: true) {
                // Очистка строки от лишних символов
                let sanitizedInput = sanitizeDateInput(inputStringDate)

                // Попытка распарсить дату с использованием предустановленных форматов
                for format in predefinedFormats {
                    if let date = dateFormattingService.parse(sanitizedInput, using: format) {
                        print("✅ Successfully parsed date: \(date) from input: \(sanitizedInput)")
                        return date
                    }
                }

                // Если все форматы не подошли, запрос формата у пользователя
                print("❌ Could not parse date: \(sanitizedInput)")
                let inputFormat = requestString(text: "Enter the date format (e.g., dd.MM.yyyy HH:mm): ")
                if let date = dateFormattingService.parse(sanitizedInput, using: .custom(inputFormat)) {
                    print("✅ Successfully parsed date with custom format: \(date)")
                    return date
                } else {
                    print("❌ Invalid date or format. Please try again.")
                }
            } else {
                print("❌ Input error. Please try again.")
            }
        }
    }

    /// Cleans the date input string, leaving only numbers, dots, colons, dashes, and spaces.
    /// - Parameter input: The raw date string input by the user.
    /// - Returns: A sanitized date string.
    private func sanitizeDateInput(_ input: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.-: ")
        return input.filter { char in
            guard let scalar = char.unicodeScalars.first else { return false }
            return allowedCharacters.contains(scalar)
        }
    }

    func requestString(text: String) -> String {
        while true {
            print("\(text): ", terminator: "")
            if let input = readLine(strippingNewline: true) {
                return input
            } else {
                print("Input error. Please try again.")
            }
        }
    }
}
