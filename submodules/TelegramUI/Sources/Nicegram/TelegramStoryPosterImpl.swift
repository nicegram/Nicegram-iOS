import AccountContext
import Display
import MemberwiseInit
import NGUtils
import TelegramBridge
import TelegramCore
import UIKit

@MemberwiseInit
class TelegramStoryPosterImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramStoryPosterImpl: TelegramStoryPoster {
    func initiateStoryPost(
        image: UIImage,
        text: String,
        onPosted: (() -> Void)?
    ) {
        do {
            let context = try contextProvider.context().unwrap()
            
            let rootController = try (context.sharedContext.mainWindow?.viewController as? TelegramRootControllerInterface).unwrap()
            
            let storyController = context.sharedContext.makeStoryMediaEditorScreen(
                context: context,
                source: image,
                text: text,
                link: nil,
                remainingCount: 1,
                completion: { [weak rootController] results, externalState, commit in
                    guard let rootController else { return }
                    
                    let target: Stories.PendingTarget = results.first!.target
                    externalState.storyTarget = target
                    
                    rootController.proceedWithStoryUpload(target: target, results: results, existingMedia: nil, forwardInfo: nil, externalState: externalState, commit: commit)
                    
                    onPosted?()
                }
            )
            
            rootController.pushViewController(storyController)
            
            dismissModalControllersIfNeeded()
        } catch {}
    }
}

private func dismissModalControllersIfNeeded() {
    let rootController = UIApplication.findKeyWindow()?.rootViewController
    if let rootController, rootController.presentedViewController != nil {
        rootController.dismiss(animated: true)
    }
}
