load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGKeywords",
    module_name = "NGKeywords",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/AccountContext:AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Nicegram/NGUtils:NGUtils",
        "//Nicegram/NGLogging:NGLogging"
    ],
    visibility = [
        "//visibility:public",
    ],
)
