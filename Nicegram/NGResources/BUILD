load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")


filegroup(
    name = "NGImagesAssets",
    srcs = glob(["Images.xcassets/**"]),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "NGResources",
    module_name = "NGResources",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [
    ],
    visibility = [
        "//visibility:public",
    ],
)
