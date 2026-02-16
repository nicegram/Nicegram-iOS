import AccountContext
import Display
import MemberwiseInit
import NGUtils
import Postbox
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
class TelegramWebAppOpenerImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramWebAppOpenerImpl: TelegramWebAppOpener {
    func open(
        appBotId: TelegramId,
        appShortName: String,
        customization: TelegramWebAppCustomization
    ) async throws {
        let context = try contextProvider.context().unwrap()
        
        let appBotId = PeerId(appBotId)

        async let botApp = getBotApp(
            context: context,
            appBotId: appBotId,
            appShortName: appShortName
        )
        
        async let botPeer = getPeer(
            context: context,
            id: appBotId
        )
        
        let mode = getMode(customization: customization)
        let topController = try getTopController(context: context)
        
        try await ChatControllerImpl.presentBotApp(
            context: context,
            parentController: topController,
            botApp: botApp,
            botPeer: botPeer,
            payload: nil,
            mode: mode,
            customization: customization
        )
    }
}

private extension TelegramWebAppOpenerImpl {
    func getBotApp(
        context: AccountContext,
        appBotId: PeerId,
        appShortName: String
    ) async throws -> BotApp {
        try await context.engine.messages.getBotApp(
            botId: appBotId,
            shortName: appShortName
        ).awaitForFirstValue()
    }
    
    func getPeer(
        context: AccountContext,
        id: PeerId
    ) async throws -> EnginePeer {
        try await context.engine.data.get(
            TelegramEngine.EngineData.Item.Peer.Peer(id: id)
        ).awaitForFirstValue().unwrap()
    }
    
    func getMode(
        customization: TelegramWebAppCustomization
    ) -> ResolvedStartAppMode {
        customization.isFullscreen() ? .fullscreen : .generic
    }
    
    func getTopController(
        context: AccountContext
    ) throws -> ViewController {
        let navigationController = context.sharedContext.mainWindow?.viewController as? NavigationController
        let topController = navigationController?.topViewController as? ViewController
        return try topController.unwrap()
    }
}
