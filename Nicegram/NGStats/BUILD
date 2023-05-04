load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGStats",
    module_name = "NGStats",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "@swiftpkg_nicegram_assistant_ios//:Sources_NGApi",
        "//submodules/AccountContext:AccountContext",
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGRemoteConfig:NGRemoteConfig",
        "//Nicegram/NGUtils:NGUtils",
    ],
    visibility = [
        "//visibility:public",
    ],
)
