import AccountContext
import Display
import FeatNicegramBusiness
import PresentationDataUtils

public func accountControlAlert(context: AccountContext) -> ViewController {
    accountControlAlert(
        nicegramBusiness: context.nicegramBusiness,
        sharedContext: context.sharedContext
    )
}

// For the sites with no AccountContext.
public func accountControlAlert(
    nicegramBusiness: NicegramBusiness,
    sharedContext: SharedAccountContext
) -> ViewController {
    let presentationData = sharedContext.currentPresentationData.with { $0 }
    return textAlertController(
        sharedContext: sharedContext,
        title: nicegramBusiness.account().map {
            FeatNicegramBusiness.strings.work_accountRestrictedTitle($0.organizationName)
        },
        text: FeatNicegramBusiness.strings.work_accountRestrictedBody(),
        actions: [
            TextAlertAction(
                type: .defaultAction,
                title: presentationData.strings.Common_OK,
                action: {}
            )
        ]
    )
}
