// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "nicegram-package",
    dependencies: [
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", from: "13.0.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git", branch: "develop"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git", branch: "develop")
    ]
)
