import AccountContext
import FeatDataSharing

public func shareStickers(context: AccountContext) {
    _ = Task {
        let shareStickersUseCase = DataSharingModule.shared.shareStickersUseCase()
        try await shareStickersUseCase(
            dataProvider: {
                await StickersDataProvider(context: context).getStickersData()
            }
        )
    }
}
