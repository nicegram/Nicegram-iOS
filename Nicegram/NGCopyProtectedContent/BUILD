load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGCopyProtectedContent",
    module_name = "NGCopyProtectedContent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGRemoteConfig:NGRemoteConfig",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGPremiumUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
