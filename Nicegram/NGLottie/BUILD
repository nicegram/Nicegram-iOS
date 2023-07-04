load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGLottie",
    module_name = "NGLottie",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/lottie-ios:Lottie",
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGCoreUI",
    ],
    visibility = ["//visibility:public"],

)
