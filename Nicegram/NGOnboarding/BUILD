load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGOnboarding",
    module_name = "NGOnboarding",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/UIKitRuntimeUtils:UIKitRuntimeUtils",
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGStrings:NGStrings",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGAiChat",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGPremiumUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
