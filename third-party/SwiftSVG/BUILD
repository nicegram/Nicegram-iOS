load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SwiftSVG",
    module_name = "SwiftSVG",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
        "//third-party/XMLCoder",
        "//third-party/Swift2D",
    ],
    visibility = [
        "//visibility:public",
    ],
)
