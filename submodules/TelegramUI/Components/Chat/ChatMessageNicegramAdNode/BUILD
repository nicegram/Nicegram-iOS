load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# todo: cleanup
swift_library(
    name = "ChatMessageNicegramAdNode",
    module_name = "ChatMessageNicegramAdNode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramUI/Components/Chat/ChatMessageItemView",
        "@swiftpkg_nicegram_assistant_ios//:FeatAdsgram",
    ],
    visibility = [
        "//visibility:public",
    ],
)
