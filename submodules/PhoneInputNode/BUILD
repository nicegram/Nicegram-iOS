load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

NGDEPS = [
    "@swiftpkg_nicegram_assistant_ios//:NGCore",
]

swift_library(
    name = "PhoneInputNode",
    module_name = "PhoneInputNode",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = NGDEPS + [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
    	"//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/PhoneNumberFormat:PhoneNumberFormat",
    ],
    visibility = [
        "//visibility:public",
    ],
)
