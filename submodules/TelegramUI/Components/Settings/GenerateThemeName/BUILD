load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "GenerateThemeName",
    module_name = "GenerateThemeName",
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
