load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "GenerateStickerPlaceholderImage",
    module_name = "GenerateStickerPlaceholderImage",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display",
    ],
    visibility = [
        "//visibility:public",
    ],
)
