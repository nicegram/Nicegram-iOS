load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

http_archive(
    name = "bazel_skylib",
    sha256 = "f24ab666394232f834f74d19e2ff142b0af17466ea0c69a3f4c276ee75f6efce",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.0/bazel-skylib-1.4.0.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.0/bazel-skylib-1.4.0.tar.gz",
    ],
)

http_archive(
    name = "bazel_features",
    sha256 = "0f23d75c7623d6dba1fd30513a94860447de87c8824570521fcc966eda3151c2",
    strip_prefix = "bazel_features-1.4.1",
    url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.4.1/bazel_features-v1.4.1.tar.gz",
)

local_repository(
    name = "rules_xcodeproj",
    path = "build-system/bazel-rules/rules_xcodeproj",
)

local_repository(
    name = "build_bazel_rules_apple",
    path = "build-system/bazel-rules/rules_apple",
)

local_repository(
    name = "build_bazel_rules_swift",
    path = "build-system/bazel-rules/rules_swift",
)

local_repository(
    name = "build_bazel_apple_support",
    path = "build-system/bazel-rules/apple_support",
)

http_file(
    name = "cmake_tar_gz",
    urls = ["https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-macos-universal.tar.gz"],
    sha256 = "f794ed92ccb4e9b6619a77328f313497d7decf8fb7e047ba35a348b838e0e1e2",
)

http_archive(
    name = "appcenter_sdk",
    urls = ["https://github.com/microsoft/appcenter-sdk-apple/releases/download/4.1.1/AppCenter-SDK-Apple-4.1.1.zip"],
    sha256 = "032907801dc7784744a1ca8fd40d3eecc34a2e27a93a4b3993f617cca204a9f3",
    build_file = "@//third-party/AppCenter:AppCenter.BUILD",
)

load(
    "@rules_xcodeproj//xcodeproj:repositories.bzl",
    "xcodeproj_rules_dependencies",
)

xcodeproj_rules_dependencies()

load("@bazel_features//:deps.bzl", "bazel_features_deps")

bazel_features_deps()

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("@build_bazel_rules_apple//apple:apple.bzl", "provisioning_profile_repository")
provisioning_profile_repository(
    name = "local_provisioning_profiles",
)

http_archive(
    name = "FirebaseSDK",
    urls = ["https://github.com/firebase/firebase-ios-sdk/releases/download/v8.11.0/Firebase.zip"],
    build_file = "@//third-party/Firebase:BUILD",
	sha256 = "ecf1013b5d616bb5d3acc7d9ddf257c06228c0a7364dd84d03989bae6af5ac5b",
)

http_archive(
    name = "AppLovin",
    urls = ["https://artifacts.applovin.com/ios/com/applovin/applovin-sdk/applovin-ios-sdk-11.10.1.zip"],
    build_file = "@//third-party/AppLovin:BUILD",
	sha256 = "4a0e3aff4634d58307332fdaa2dbad59e4b2534a48c829aa5002d88364685c0d",
)

# swift_bazel start

http_archive(
    name = "rules_swift_package_manager",
    sha256 = "eef16c8a5f9fa6102049f762823e773601a44398baf2a5de7ef7cbebcb888870",
    urls = [
        "https://github.com/cgrindel/rules_swift_package_manager/releases/download/v0.28.0/rules_swift_package_manager.v0.28.0.tar.gz",
    ],
)

load("@rules_swift_package_manager//:deps.bzl", "swift_bazel_dependencies")

swift_bazel_dependencies()

load("@cgrindel_bazel_starlib//:deps.bzl", "bazel_starlib_dependencies")

bazel_starlib_dependencies()

# MARK: - Gazelle

# gazelle:repo bazel_gazelle

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@rules_swift_package_manager//:go_deps.bzl", "swift_bazel_go_dependencies")
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

# Declare Go dependencies before calling go_rules_dependencies.
swift_bazel_go_dependencies()

go_rules_dependencies()

go_register_toolchains(version = "1.21.1")

gazelle_dependencies()

# MARK: - Swift Toolchain

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)
load("//:swift_deps.bzl", "swift_dependencies")

# gazelle:repository_macro swift_deps.bzl%swift_dependencies
swift_dependencies()

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

#swift_bazel finish
