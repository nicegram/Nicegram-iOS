load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGUtils",
    module_name = "NGUtils",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext:AccountContext",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGAnalytics",
    ],
    visibility = [
        "//visibility:public",
    ],
)
