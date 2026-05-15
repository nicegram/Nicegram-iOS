load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGData",
    module_name = "NGData",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//Nicegram/NGRequests:NGRequests",
        "//Nicegram/NGLogging:NGLogging",
        "//Nicegram/NGEnv:NGEnv",
        "//Nicegram/NGAppCache:NGAppCache",
        "@swiftpkg_nicegram_assistant_ios//:NGCore",
        "@swiftpkg_nicegram_assistant_ios//:FeatBilling",
        "@swiftpkg_nicegram_assistant_ios//:FeatSpeechToText"
    ],
    visibility = [
        "//visibility:public",
    ],
)
