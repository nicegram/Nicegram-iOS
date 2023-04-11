load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGAppCache",
    module_name = "NGAppCache",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGCore"
    ],
    visibility = [
        "//visibility:public",
    ],
)
