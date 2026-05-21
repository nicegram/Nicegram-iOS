public struct NGDefaultPrivacySettingsApplyer {
    public static func applyDefaultPrivacySettings(for context: AccountContext) async throws {
        try? await context.engine.privacy.updatePrivacyToRecommended()
        let _ = context.engine.contacts.updateIsContactSynchronizationEnabled(isContactSynchronizationEnabled: false).start()
    }
}
