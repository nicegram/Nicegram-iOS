"""Embeds the standalone, xcodebuild-built tgwatch watch app into the Bazel iOS build.

`apple_prebuilt_watchos_application` runs `xcodebuild` (via prebuilt_watchos_build.sh)
against an exported tgwatch source tree, optionally codesigns the result, and exposes
it through the providers that `ios_application(watch_application = ...)` consumes:

  * AppleBundleInfo      — bundle metadata (the host reads only `.product_type`).
  * AppleEmbeddableInfo  — `watch_bundles` (the zipped .app placed under Watch/).

The watch source tree is the committed in-repo snapshot at `Telegram/WatchApp/` (tracked
inputs). To update it, re-sync from the standalone tgwatch repo via
`tgwatch/tools/export-sources.sh`.

Notes on the rules_apple providers used here:
  * AppleBundleInfo's public init is banned; we build it with the internal raw
    initializer `new_applebundleinfo` (rules_apple is vendored + pinned in this repo,
    so depending on the internal label is safe).
"""

load(
    "@build_bazel_rules_apple//apple/internal:providers.bzl",
    "new_applebundleinfo",
    "new_watchosapplicationbundleinfo",
)
load("@build_bazel_rules_apple//apple/internal/providers:embeddable_info.bzl", "AppleEmbeddableInfo")

def _apple_prebuilt_watchos_application_impl(ctx):
    # The watch app is built from the committed in-repo snapshot at Telegram/WatchApp,
    # tracked as inputs (incremental + cacheable).
    source_path = ctx.attr.in_repo_source_dir
    api_id = ctx.var.get("watchApiId", "0")
    api_hash = ctx.var.get("watchApiHash", "placeholder")
    identity = ctx.var.get("watchSigningIdentity", "")

    # The provisioning profile is an external, machine-specific absolute path passed via
    # --define rather than a Bazel label, so the gitignored profile need not be exposed as
    # a target. The local action reads it directly. Empty => unsigned build; when set but
    # the identity is empty, the worker derives the signing identity from the profile.
    profile = ctx.var.get("watchProvisioningProfile", "")
    # The embedded watch app's CFBundleShortVersionString / CFBundleVersion must match
    # the host app, or rules_apple's child-version verification fails. Source the
    # marketing version from versions.json (same as the host's VersionInfoPlist) and the
    # build version from buildNumber (Make.py always emits --define=buildNumber).
    build_number = ctx.var.get("buildNumber", "1")
    archive = ctx.actions.declare_file(ctx.label.name + ".zip")
    # The host ios_application reads the watch app's Info.plist (via AppleBundleInfo.infoplist)
    # to verify WKCompanionAppBundleIdentifier against the host bundle id, so expose it as a
    # separate output (resources.bzl bundle_verification crashes on a None infoplist).
    infoplist = ctx.actions.declare_file(ctx.label.name + "_Info.plist")

    # Track the in-repo snapshot so the watch build re-runs only when it changes.
    inputs = [ctx.file._worker, ctx.file.versions_json] + ctx.files.srcs
    exec_requirements = {
        "no-sandbox": "1",
        "no-remote": "1",
        "local": "1",
        "requires-network": "1",
    }

    ctx.actions.run(
        executable = "/bin/bash",
        arguments = [
            ctx.file._worker.path,
            source_path,
            archive.path,
            api_id,
            api_hash,
            identity,
            profile,
            infoplist.path,
            ctx.file.versions_json.path,
            build_number,
            # Watch app bundle id ("<host>.watchkitapp"). xcodebuild bakes it as
            # PRODUCT_BUNDLE_IDENTIFIER so the signed CFBundleIdentifier matches the host
            # config; the Info.plist derives WKCompanionAppBundleIdentifier from it via
            # $(PRODUCT_BUNDLE_IDENTIFIER:base). Keeps the build dynamic across hosts with
            # no post-build plist mutation (xcodebuild bakes, the worker signs once).
            ctx.attr.bundle_id,
        ],
        inputs = inputs,
        outputs = [archive, infoplist],
        mnemonic = "PrebuiltWatchosBuild",
        progress_message = "Building%s watch app via xcodebuild" % (" + signing" if profile else ""),
        execution_requirements = exec_requirements,
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(files = depset([archive])),
        new_applebundleinfo(
            archive = archive,
            bundle_id = ctx.attr.bundle_id,
            bundle_name = ctx.attr.bundle_name,
            bundle_extension = ".app",
            platform_type = "watchos",
            # Must be a single-target watchOS app (NOT watch2_application) so the host
            # skips the watchos_stub partial (see ios_rules.bzl product_type check).
            product_type = "com.apple.product-type.application",
            minimum_os_version = ctx.attr.minimum_os_version,
            minimum_deployment_os_version = ctx.attr.minimum_os_version,
            infoplist = infoplist,
            binary = None,
            entitlements = None,
            # Best-effort constant; the host ios_application reads only product_type.
            uses_swift = True,
            extension_safe = False,
        ),
        # Marker provider required by ios_application's watch_application attr
        # (providers = [[AppleBundleInfo, WatchosApplicationBundleInfo]]).
        new_watchosapplicationbundleinfo(),
        AppleEmbeddableInfo(
            # The signed (or unsigned) .app archive, expanded into the host's Watch/ section.
            watch_bundles = depset([archive]),
            # Empty: the worker signs everything inside the watch app itself.
            signed_frameworks = depset(),
        ),
    ]

apple_prebuilt_watchos_application = rule(
    implementation = _apple_prebuilt_watchos_application_impl,
    attrs = {
        "bundle_id": attr.string(default = "ph.telegra.Telegraph.watchkitapp"),
        "bundle_name": attr.string(default = "tgwatch Watch App"),
        "minimum_os_version": attr.string(default = "26.0"),
        "srcs": attr.label(
            default = "//Telegram/WatchApp:sources",
            allow_files = True,
            doc = "Committed in-repo watch source snapshot (tracked inputs).",
        ),
        "in_repo_source_dir": attr.string(
            default = "Telegram/WatchApp",
            doc = "Execroot-relative path to the committed snapshot (must match the package of 'srcs').",
        ),
        "versions_json": attr.label(
            allow_single_file = True,
            default = "//:versions.json",
            doc = "Source of the marketing version (key 'app'), kept in sync with the host app.",
        ),
        "_worker": attr.label(
            default = "//Telegram:prebuilt_watchos_build.sh",
            allow_single_file = True,
        ),
    },
)
