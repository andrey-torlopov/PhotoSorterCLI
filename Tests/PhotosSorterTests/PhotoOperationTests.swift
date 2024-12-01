import Testing
@testable import PhotosSorter

/// Tests for PhotoOperation enum
struct PhotoOperationTests {

    @Test("PhotoOperation initializes with valid raw values")
    func testValidInitialization() {
        #expect(PhotoOperation(rawValue: "1") == .convertDngToHeic)
        #expect(PhotoOperation(rawValue: "2") == .sortPhotos)
        #expect(PhotoOperation(rawValue: "3") == .fixDate)
        #expect(PhotoOperation(rawValue: "4") == .forceDateSet)
        #expect(PhotoOperation(rawValue: "5") == .checkValidDateAndName)
        #expect(PhotoOperation(rawValue: "6") == .convertPngToHeic)
        #expect(PhotoOperation(rawValue: "0") == .exit)
    }

    @Test("PhotoOperation returns nil for invalid raw values")
    func testInvalidInitialization() {
        #expect(PhotoOperation(rawValue: "7") == nil)
        #expect(PhotoOperation(rawValue: "-1") == nil)
        #expect(PhotoOperation(rawValue: "abc") == nil)
        #expect(PhotoOperation(rawValue: "") == nil)
        #expect(PhotoOperation(rawValue: " ") == nil)
    }

    @Test("PhotoOperation raw values are correct")
    func testRawValues() {
        #expect(PhotoOperation.convertDngToHeic.rawValue == "1")
        #expect(PhotoOperation.sortPhotos.rawValue == "2")
        #expect(PhotoOperation.fixDate.rawValue == "3")
        #expect(PhotoOperation.forceDateSet.rawValue == "4")
        #expect(PhotoOperation.checkValidDateAndName.rawValue == "5")
        #expect(PhotoOperation.convertPngToHeic.rawValue == "6")
        #expect(PhotoOperation.exit.rawValue == "0")
    }

    @Test("All PhotoOperation cases are unique")
    func testUniqueness() {
        let allCases: [PhotoOperation] = [
            .convertDngToHeic,
            .sortPhotos,
            .fixDate,
            .forceDateSet,
            .checkValidDateAndName,
            .convertPngToHeic,
            .exit
        ]

        let rawValues = allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)

        #expect(rawValues.count == uniqueRawValues.count)
    }
}
