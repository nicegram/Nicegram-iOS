load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGKeywords",
    module_name = "NGKeywords",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext",
        "//submodules/AccountUtils",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramApi",
        "//Nicegram/NGLogging",
        "//Nicegram/NGUI",
        "//Nicegram/NGUtils",
        "@swiftpkg_nicegram_assistant_ios//:FeatKeywords",
    ],
    visibility = [
        "//visibility:public",
    ],
)
