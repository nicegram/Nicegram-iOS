load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGDataSharing",
    module_name = "NGDataSharing",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Nicegram/NGLogging:NGLogging",
        "//Nicegram/NGUtils:NGUtils",
        "//submodules/AccountContext:AccountContext",
        "//submodules/MtProtoKit:MtProtoKit",
        # TelegramApi is imported but not listed: its visibility admits only TelegramCore, so the module comes through TelegramCore's transitive search path.
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "@swiftpkg_nicegram_assistant_ios//:FeatDataSharing",
    ],
    visibility = [
        "//visibility:public",
    ],
)
