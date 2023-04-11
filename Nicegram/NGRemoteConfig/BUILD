load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGRemoteConfig",
    module_name = "NGRemoteConfig",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@FirebaseSDK//:FirebaseRemoteConfig",
        "@swiftpkg_nicegram_assistant_ios//:Sources__NGRemoteConfig",
        "//Nicegram/NGEnv:NGEnv",
    ],
    visibility = ["//visibility:public"],

)
