load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGPersonalityCore",
    module_name = "NGPersonalityCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_nicegram_assistant_ios//:FeatPersonality",
        "@swiftpkg_nicegram_assistant_ios//:FeatPersonalityUI"
    ],
    visibility = [
        "//visibility:public",
    ],
)
