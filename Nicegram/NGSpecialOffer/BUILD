load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGSpecialOffer",
    module_name = "NGSpecialOffer",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGCoreUI",
        "@swiftpkg_snapkit//:Sources_SnapKit",
        "//submodules/lottie-ios:Lottie",
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGLocalization:NGLocalization",
        "//Nicegram/NGLogging:NGLogging",
        "//Nicegram/NGRemoteConfig:NGRemoteConfig",
        "//Nicegram/NGTheme:NGTheme",
    ],
    visibility = ["//visibility:public"],

)
