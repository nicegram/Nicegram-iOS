load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AppLovinAdProvider",
    module_name = "AppLovinAdProvider",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_applovin_max_swift_package//:AppLovinSDK",
        "@swiftpkg_nicegram_assistant_ios//:NGAiChat",
    ],
    visibility = ["//visibility:public"],

)
