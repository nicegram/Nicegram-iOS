import AccountContext
import Display
import MemberwiseInit
import NGCore
import NGUtils
import SwiftSignalKit
import TelegramBridge
import TelegramCore
import UIKit

@MemberwiseInit
final class TelegramNavigatorImpl {
    @Init(.internal) private let contextProvider: ContextProvider
    @Init(.internal) private let inFlightOnboarding: @MainActor () -> InFlightOnboarding?
    @Init(.internal) private let sharedContextProvider: SharedContextProvider
}

extension TelegramNavigatorImpl: TelegramNavigator {
    // Telegram's own stack stays as it is: TelegramStoryPosterImpl pushes its editor and then calls this
    func dismissToTelegram() {
        if let onboarding = inFlightOnboarding() {
            onboarding.finish()
        } else {
            dismissPresentedViewControllers()
        }
    }

    func navigateToAccount(_ id: TelegramId) {
        _ = Task {
            // Not through contextProvider: it names only the current account, and the shared context's account list can switch to any signed-in one
            let sharedContext = try await sharedContextProvider.sharedContext()
            let peerId = EnginePeer.Id(id)
            let (_, accounts, _) = try await sharedContext.activeAccountContexts.awaitForFirstValue()
            if let account = accounts.first(where: { $0.1.account.peerId == peerId }) {
                sharedContext.switchToAccount(
                    id: account.1.account.id,
                    fromSettingsController: nil,
                    withChatListController: nil
                )
            }
        }
        
        dismissToTelegram()
    }

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

private extension TelegramNavigatorImpl {
    func dismissPresentedViewControllers() {
        let rootController = UIApplication.findKeyWindow()?.rootViewController
        if let rootController, rootController.presentedViewController != nil {
            rootController.dismiss(animated: true)
        }
    }
}
