// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BasicBreathExercise",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "BasicBreathExercise", path: "Sources/BasicBreathExercise")
    ]
)
