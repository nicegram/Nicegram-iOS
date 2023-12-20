load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGRoundedVideos",
    module_name = "NGRoundedVideos",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGAppCache:NGAppCache",
        "//Nicegram/NGStrings:NGStrings",
    ],
    visibility = ["//visibility:public"],

)
