load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGCallRecorder",
    module_name = "NGCallRecorder",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//Nicegram/NGData",
        "//Nicegram/NGStrings",
        "//Nicegram/NGUtils",
        "//submodules/AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramVoip",
        "//submodules/UndoUI",
        "@swiftpkg_nicegram_assistant_ios//:FeatCallRecorder",
    ],
    visibility = [
        "//visibility:public",
    ],
)
