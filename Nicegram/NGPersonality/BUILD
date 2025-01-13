load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGPersonality",
    module_name = "NGPersonality",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramApi:TelegramApi",
        "//submodules/AccountContext:AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "@swiftpkg_nicegram_assistant_ios//:FeatPersonality"        
    ],
    visibility = [
        "//visibility:public",
    ],
)
