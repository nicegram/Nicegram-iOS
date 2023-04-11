load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SubscriptionAnalytics",
    module_name = "SubscriptionAnalytics",
    srcs = glob([
        "**/*.swift",
    ]),
    visibility = ["//visibility:public"],
    deps = [
        "@swiftpkg_swiftystorekit//:Sources_SwiftyStoreKit",
        "//Nicegram/NGAppCache:NGAppCache",
        "//Nicegram/NGEnv:NGEnv",
    ],
)
