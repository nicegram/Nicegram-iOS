load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGCollectInformation",
    module_name = "NGCollectInformation",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/AccountContext:AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Nicegram/NGUtils:NGUtils",
        "//Nicegram/NGLogging:NGLogging",
        "@swiftpkg_nicegram_assistant_ios//:FeatCollectInformation"
    ],
    visibility = [
        "//visibility:public",
    ],
)
