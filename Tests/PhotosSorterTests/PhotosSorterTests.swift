import Testing
@testable import PhotosSorter

/// Basic smoke test to verify test infrastructure
@Test("Basic smoke test")
func smokeTest() {
    // Basic test to verify test infrastructure works
    #expect(Bool(true))
}

@Test("PhotosSorter module is available")
func testModuleAvailability() {
    // Verify that we can access PhotoOperation from the module
    let operation = PhotoOperation.exit
    #expect(operation.rawValue == "0")
}
