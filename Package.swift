// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "nicegram-package",
    dependencies: [
        // When using versions 13.3.0-13.3.1 push notifications are broken (not coming)
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", exact: "13.2.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git", branch: "feat/disable-tg-notifications-splash"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git", branch: "develop")
    ]
)
