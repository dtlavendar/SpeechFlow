// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpeechFlow",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "SpeechFlow", targets: ["SpeechFlow"]),
    ],
    targets: [
        .target(name: "SpeechFlowCore"),
        .target(
            name: "SpeechFlowVault",
            dependencies: ["SpeechFlowCore"]
        ),
        .target(
            name: "SpeechFlowConnectors",
            dependencies: ["SpeechFlowCore"]
        ),
        .target(
            name: "SpeechFlowInference",
            dependencies: ["SpeechFlowCore"]
        ),
        .target(
            name: "SpeechFlowDictation",
            dependencies: ["SpeechFlowCore"]
        ),
        .target(
            name: "SpeechFlowUI",
            dependencies: [
                "SpeechFlowCore",
                "SpeechFlowVault",
                "SpeechFlowConnectors",
                "SpeechFlowInference",
                "SpeechFlowDictation",
            ]
        ),
        .executableTarget(
            name: "SpeechFlow",
            dependencies: ["SpeechFlowUI"]
        ),
    ]
)
