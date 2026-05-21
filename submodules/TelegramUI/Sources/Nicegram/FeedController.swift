import UIKit
import Display
import AccountContext
import SwiftSignalKit
import NGData
import NGStrings

final class FeedController: ViewController {
    private let context: AccountContext

    private var feedController: ChatController?
    private var updateFeedDiposable: Disposable?
    
    init(context: AccountContext) {
        self.context = context
        super.init(navigationBarPresentationData: nil)

        let image = UIImage(bundleImageName: "feed")?
            .sd_resizedImage(with: .init(width: 30, height: 30), scaleMode: .aspectFit)?
            .withRenderingMode(.alwaysTemplate)
        tabBarItem = UITabBarItem(
            title: l("NicegramFeed.Title"),
            image: image,
            tag: 1
        )
        
        _ = context.sharedContext.presentationData.start { [weak self] presentationData in
            self?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
        }

        self.updateFeedDiposable = (context.updateFeed |> deliverOnMainQueue).start(next: { [weak self] _ in
            guard let self else { return }
            
            self.setupFeed(with: context)
        })
        
        
        if NGSettings.feedPeer[context.account.id.int64] != nil {
            setupFeed(with: context)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        updateFeedDiposable?.dispose()
        updateFeedDiposable = nil
    }
    
    override func containerLayoutUpdated(
        _ layout: ContainerViewLayout,
        transition: ContainedViewLayoutTransition
    ) {
        super.containerLayoutUpdated(layout, transition: transition)

        feedController?.view.frame = view.bounds
        feedController?.containerLayoutUpdated(layout, transition: transition)
    }

    private func setupFeed(
        with context: AccountContext
    ) {
        guard let id = NGSettings.feedPeer[context.account.id.int64] else { return }

        feedController?.removeFromParent()
        feedController?.view.removeFromSuperview()

        let feedController = ChatControllerImpl(
            context: context,
            chatLocation: .peer(id: id),
            isFeed: true
        )
        
        addChild(feedController)
        view.addSubview(feedController.view)

        self.feedController = feedController
    }
}
