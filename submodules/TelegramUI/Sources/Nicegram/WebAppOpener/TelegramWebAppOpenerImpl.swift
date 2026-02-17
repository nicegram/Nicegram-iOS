import AccountContext
import Display
import MemberwiseInit
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramBridge
import TelegramCore

@MemberwiseInit(.public)
class TelegramWebAppOpenerImpl {
    @Init(.public) private let contextProvider: ContextProvider
}

extension TelegramWebAppOpenerImpl: TelegramWebAppOpener {
    func open(
        appBotName: String,
        appShortName: String,
        customization: TelegramWebAppCustomization
    ) async throws {
        let context = try contextProvider.context().unwrap()
        
        let botPeer = try await getPeer(
            context: context,
            username: appBotName
        )

        let botApp = try await getBotApp(
            context: context,
            appBotId: botPeer.id,
            appShortName: appShortName
        )
        
        let mode = getMode(customization: customization)
        let topController = try getTopController(context: context)
        
        ChatControllerImpl.presentBotApp(
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
        username: String
    ) async throws -> EnginePeer {
        let peerSignal = context.engine.peers.resolvePeerByName(name: username, referrer: nil)
        |> mapToSignal { result -> Signal<EnginePeer?, NoError> in
            guard case let .result(result) = result else {
                return .complete()
            }
            return .single(result)
        }
        return try await peerSignal.awaitForFirstValue().unwrap()
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
