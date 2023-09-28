sudo xcode-select -s /Applications/Xcode_14.3.1.app

bazel run //:swift_update_pkgs_to_latest

sudo xcode-select -s /Applications/Xcode_15.0.app
