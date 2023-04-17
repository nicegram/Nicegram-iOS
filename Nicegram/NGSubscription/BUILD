load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGSubscription",
    module_name = "NGSubscription",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
		"@swiftpkg_nicegram_assistant_ios//:Sources_NGPremium",
		"//Nicegram/SubscriptionAnalytics:SubscriptionAnalytics",
    ],
    visibility = [
        "//visibility:public",
    ],
)
