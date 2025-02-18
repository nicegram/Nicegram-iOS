// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "nicegram-package",
    dependencies: [
        .package(url: "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git", branch: "feat/NCG-7303_spy_on_friends"),
        .package(url: "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git", branch: "develop")
    ]
)
