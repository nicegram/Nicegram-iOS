# Install Fastlane
brew install fastlane

# Install sentry-cli (for dSYM upload)
brew install getsentry/tools/sentry-cli

# Sync code signing
./nicegram-match.sh development

# Create build working directory
mkdir working_dir
