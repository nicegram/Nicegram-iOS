load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NGStealthMode",
    module_name = "NGStealthMode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramUIPreferences:TelegramUIPreferences",
        "@swiftpkg_nicegram_assistant_ios//:NGCore",
    ],
    visibility = [
        "//visibility:public",
    ],
)
