load("@rules_swift_package_manager//swiftpkg:defs.bzl", "swift_package")

def swift_dependencies():
    # version: 2.1.3
    swift_package(
        name = "swiftpkg_factory",
        commit = "8ca11a7bd1ede031e8e6d7a912bb116e2e43961b",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/hmlongco/Factory",
    )

    # version: 2.6.1
    swift_package(
        name = "swiftpkg_floatingpanel",
        commit = "5b33d3d5ff1f50f4a2d64158ccfe8c07b5a3e649",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/scenee/FloatingPanel",
    )

    # branch: master
    swift_package(
        name = "swiftpkg_grdb.swift",
        commit = "58d3673030f8a640d7278f45bf2dc21b078ecae8",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/GRDB.swift.git",
    )

    # version: 1.2.0
    swift_package(
        name = "swiftpkg_lnextensionexecutor",
        commit = "16b741f659e344f4569c9f9d32ef2298ef0233ff",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/LeoNatan/LNExtensionExecutor",
    )

    # branch: develop
    swift_package(
        name = "swiftpkg_nicegram_assistant_ios",
        commit = "123eb001dcc9477f9087e40ff1b0e7f012182d45",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "git@bitbucket.org:mobyrix/nicegram-assistant-ios.git",
    )

    # version: 7.3.2
    swift_package(
        name = "swiftpkg_r.swift",
        commit = "4a0f8c97f1baa27d165dc801982c55bbf51126e5",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/denis15yo/R.swift.git",
    )

    # version: 5.15.5
    swift_package(
        name = "swiftpkg_sdwebimage",
        commit = "b11493f76481dff17ac8f45274a6b698ba0d3af5",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/SDWebImage/SDWebImage.git",
    )

    # version: 5.6.0
    swift_package(
        name = "swiftpkg_snapkit",
        commit = "2842e6e84e82eb9a8dac0100ca90d9444b0307f4",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/SnapKit/SnapKit.git",
    )

    # version: 0.4.3
    swift_package(
        name = "swiftpkg_subscriptionanalytics_ios",
        commit = "53bfc6c6f26322ec647b87c338a071714ac69420",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "git@bitbucket.org:mobyrix/subscriptionanalytics-ios.git",
    )

    # version: 1.2.3
    swift_package(
        name = "swiftpkg_swift_argument_parser",
        commit = "c8ed701b513cf5177118a175d85fbbbcd707ab41",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/apple/swift-argument-parser",
    )

    # version: 0.16.4
    swift_package(
        name = "swiftpkg_swiftystorekit",
        commit = "9ce911639680113dac9b554d6243e406a9758ebe",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/bizz84/SwiftyStoreKit.git",
    )

    # version: 2.9.0
    swift_package(
        name = "swiftpkg_xcodeedit",
        commit = "b6b67389a0f1a6fdd9c6457a8ab5b02eaab13c5c",
        dependencies_index = "@//:swift_deps_index.json",
        remote = "https://github.com/tomlokhorst/XcodeEdit",
    )
