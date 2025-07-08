import AccountContext
import FeatDataSharing

public func shareStickers(context: AccountContext) {
    Task {
        let shareStickersUseCase = DataSharingModule.shared.shareStickersUseCase()
        try await shareStickersUseCase(
            dataProvider: {
                await StickersDataProvider(context: context).getStickersData()
            }
        )
    }
}
