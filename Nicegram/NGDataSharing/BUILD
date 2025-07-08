load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGDataSharing",
    module_name = "NGDataSharing",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGUtils:NGUtils",
        "//Nicegram/NGLogging:NGLogging",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "@swiftpkg_nicegram_assistant_ios//:FeatDataSharing"
    ],
    visibility = [
        "//visibility:public",
    ],
)
