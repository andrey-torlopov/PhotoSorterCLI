import Foundation
import PhotoSorterCore

/// Core's xattr command reports success/failure as a typed event. Its inherited stderr
/// would bypass terminal language selection, so discard only the subprocess's raw text.
/// Arguments, execution and exit-status semantics are unchanged from Core's executor.
struct CLICommandExecutor: SystemCommandExecuting {
    func execute(executable: URL, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
