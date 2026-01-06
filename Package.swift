// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "nicegram-package",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.0.0"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git", branch: "develop"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git", revision: "25407f4a868e94b2ab3b5cb13b2fa0ab4b917b25")
    ]
)
