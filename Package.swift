// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PhotosSorter",
    platforms: [.macOS(.v15)],
    products: [
        .executable(
            name: "photos-sorter-cli", // Имя исполняемого файла
            targets: ["PhotosSorter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/andrey-torlopov/PhotoSorterCore", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "PhotosSorter",
            dependencies: [
                "PhotoSorterCore"
            ]
        ),
        .testTarget(
            name: "PhotosSorterTests",
            dependencies: ["PhotosSorter"]
        ),
    ]
)
