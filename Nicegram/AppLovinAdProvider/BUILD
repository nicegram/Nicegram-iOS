load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AppLovinAdProvider",
    module_name = "AppLovinAdProvider",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@AppLovin//:AppLovin",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGAiChat",
    ],
    visibility = ["//visibility:public"],

)
