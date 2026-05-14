
objc_library(
    name = "LegacyImpl",
    enable_modules = True,
    module_name = "LegacyImpl",
    srcs = glob([
        "Sources/**/*.m",
        "Sources/**/*.c",
        "Sources/**/*.h",
    ]),
    hdrs = glob([
        "PublicHeaders/**/*.h",
    ]),
    includes = [
        "PublicHeaders",
    ],
    sdk_frameworks = [
        "Foundation",
    ],
    visibility = [
        "//visibility:public",
    ],
)
