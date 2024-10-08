load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGCallRecorder",
    module_name = "NGCallRecorder",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/ComponentFlow",
        "//submodules/Display"
    ],
    visibility = [
        "//visibility:public",
    ],
)
