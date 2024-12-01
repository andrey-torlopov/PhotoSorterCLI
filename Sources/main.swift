import Foundation
import PhotoSorterCore

@available(macOS 13.0, *)
func main() async {
    while true {
        print("")
        print("""
        ██████╗ ██╗  ██╗ ██████╗ ████████╗ ██████╗ ███████╗
        ██╔══██╗██║  ██║██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝
        ██████╔╝███████║██║   ██║   ██║   ██║   ██║███████╗
        ██╔═══╝ ██╔══██║██║   ██║   ██║   ██║   ██║╚════██║
        ██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝███████║
        ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝
        ───────────────────────────────────────────────────
           Andrey Torlopov · torlopov.mail@ya.ru
        ───────────────────────────────────────────────────
        """)
        print("------------------------------")
        print("Select a command: (0 - exit)")
        print("1. Convert DNG to HEIC")
        print("2. Sort files into folders: Photos(Videos)/<Year>/<Month>")
        print("3. Fix dates in files")
        print("4. Set a specific date in files")
        print("5. Check if the file's name date matches the internal date")
        print("6. Convert PNG to HEIC")
        print("")
        print("Your choice: ", terminator: "")

        // Read user input
        if let inputOption = readLine(strippingNewline: true),
           let operation = PhotoOperation(rawValue: inputOption) {
            switch operation {
            case .convertDngToHeic:
                let converter = ConvertToHeicScript()
                await converter.run(from: .dng)

            case .sortPhotos:
                let script = SorterScript()
                 await script.run()

            case .forceDateSet:
                let script = FixDateScript()
                 script.runForceSetDate()

            case .fixDate:
                let script = FixDateScript()
                 await script.runFixDate()

            case .checkValidDateAndName:
                let script = FixDateScript()
                 await script.runCheckValidDateAndName()

            case .convertPngToHeic:
                let converter = ConvertToHeicScript()
                await converter.run(from: .png)

            case .exit:
                print("Exiting the program...")
                exit(0)  // Stop the program
            }
        } else {
            print("Invalid input. Please try again.")
        }
    }
}

if #available(macOS 13.0, *) {
    Task {
        await main()
    }
    RunLoop.main.run()
} else {
    print("This application requires macOS 13.0 or newer.")
}
