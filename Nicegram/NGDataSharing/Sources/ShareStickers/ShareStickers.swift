import AccountContext
import FeatDataSharing
import NGUtils

public func shareStickers(context: AccountContext) {
    // Nicegram Business, work-account data sharing: share-stickers
    guard !context.nicegramBusiness.restrictsAccountControl() else {
        return
    }
    //
    _ = Task {
        let shareStickersUseCase = DataSharingModule.shared.shareStickersUseCase()
        try await shareStickersUseCase(
            dataProvider: {
                await StickersDataProvider(context: context).getStickersData()
            }
        )
    }
}
