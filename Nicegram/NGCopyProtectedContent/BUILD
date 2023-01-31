load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGCopyProtectedContent",
    module_name = "NGCopyProtectedContent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//Nicegram/NGCore:NGCore",
        "//Nicegram/NGData:NGData",
        "//Nicegram/NGRemoteConfig:NGRemoteConfig",
		"//Nicegram/NGSubscription:NGSubscription",
    ],
    visibility = [
        "//visibility:public",
    ],
)
