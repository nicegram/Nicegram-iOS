
objc_library(
    name = "GZip",
    enable_modules = True,
    module_name = "GZip",
    srcs = glob([
        "Sources/**/*.m",
    ]),
    hdrs = glob([
        "Sources/**/*.h",
    ]),
    includes = [
        "Sources",
    ],
    sdk_dylibs = [
        "libz",
    ],
    visibility = [
        "//visibility:public",
    ],
)
