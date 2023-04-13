load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGLoadingIndicator",
    module_name = "NGLoadingIndicator",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_snapkit//:Sources_SnapKit",
        "//submodules/lottie-ios:Lottie",
    ],
    visibility = [
        "//visibility:public",
    ],
)
