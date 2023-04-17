load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGOnboarding",
    module_name = "NGOnboarding",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGStrings:NGStrings",
        "//Nicegram/NGTheme:NGTheme",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGPremiumUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
