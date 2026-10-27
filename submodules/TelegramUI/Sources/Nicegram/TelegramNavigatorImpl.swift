import AccountContext
import Display
import MemberwiseInit
import NGUtils
import TelegramBridge
import TelegramCore

@MemberwiseInit
class TelegramNavigatorImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramNavigatorImpl: TelegramNavigator {
    func navigateToChat(_ id: TelegramId) {
        _ = Task {
            let context = try contextProvider.context().unwrap()
            let sharedContext = context.sharedContext
            let peerId = EnginePeer.Id(id)
            
            let navigationController = try (sharedContext.mainWindow?.viewController as? NavigationController).unwrap()
            
            let peer = try await context.engine.data
                .get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
                .awaitForFirstValue()
                .unwrap()
            
            context.sharedContext.navigateToChatController(
                NavigateToChatControllerParams(
                    navigationController: navigationController,
                    context: context,
                    chatLocation: .peer(peer),
                    keepStack: .always
                )
            )
        }
    }
}
