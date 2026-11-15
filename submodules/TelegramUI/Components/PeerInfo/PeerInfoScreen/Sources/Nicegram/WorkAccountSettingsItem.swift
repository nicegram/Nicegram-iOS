import AccountContext
import FeatNicegramBusiness
import NGCore
import NGUtils

func workAccountSettingsItem(context: AccountContext) -> PeerInfoScreenDisclosureItem? {
    guard let businessAccount = context.nicegramBusiness.account() else {
        return nil
    }

    return PeerInfoScreenDisclosureItem(
        id: 0,
        label: .text(businessAccount.organizationName),
        text: FeatNicegramBusiness.strings.work_accountSettingsTitle(),
        icon: FeatNicegramBusiness.images.settingsWorkAccount(),
        action: {
            Task { @MainActor in
                CoreContainer.shared.urlOpener().open(NGCore.links.nicegramBusinessDashboard)
            }
        }
    )
}
