load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGStats",
    module_name = "NGStats",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGUtils:NGUtils",
        "//Nicegram/NGLogging:NGLogging",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "@swiftpkg_nicegram_assistant_ios//:FeatNicegramHub"
    ],
    visibility = [
        "//visibility:public",
    ],
)
