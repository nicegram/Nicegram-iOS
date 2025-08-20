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
        "//submodules/AccountContext",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramVoip",
        "//submodules/UndoUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
