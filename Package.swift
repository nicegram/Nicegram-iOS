// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "nicegram-package",
    dependencies: [
        .package(url: "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git", branch: "qa/build-388"),        
        .package(url: "git@bitbucket.org:mobyrix/nicegram-wallet-ios.git", branch: "qa/build-388")
    ]
)
