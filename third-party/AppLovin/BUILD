load(
    "@build_bazel_rules_apple//apple:apple.bzl",
    "apple_static_xcframework_import"
)

apple_static_xcframework_import(
    name = "AppLovin",
    xcframework_imports = glob([
		"applovin-ios-sdk-11.10.1/AppLovinSDK.xcframework/**",
	]),
    deps = [

    ],
    visibility = ["//visibility:public"],
)