load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGRemoteConfig",
    module_name = "NGRemoteConfig",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_firebase_ios_sdk//:FirebaseRemoteConfig",
        "@swiftpkg_nicegram_assistant_ios//:_NGRemoteConfig",
        "//Nicegram/NGEnv:NGEnv",
    ],
    visibility = ["//visibility:public"],

)
