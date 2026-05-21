load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "VectorPlus",
    module_name = "VectorPlus",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//third-party/SwiftColor",
        "//third-party/SwiftSVG",
    ],
    visibility = [
        "//visibility:public",
    ],
)
