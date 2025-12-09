import AccountContext
import UIKit
import Display

public class NativeControllerWrapper: ViewController {

    private let accountContext: AccountContext
    private let controller: UIViewController

    public override var childForStatusBarStyle: UIViewController? {
        return controller
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return controller.supportedInterfaceOrientations
    }

    //  MARK: - Lifecycle

    public init(
        controller: UIViewController,
        accountContext: AccountContext,
    ) {
        self.controller = controller
        self.accountContext = accountContext

        super.init(navigationBarPresentationData: nil)
        
        _ = accountContext.sharedContext.presentationData.start { [weak self] presentationData in
            self?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.addControllerIfNeeded()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.addControllerIfNeeded()
        controller.viewWillAppear(animated)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller.viewDidAppear(animated)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        controller.additionalSafeAreaInsets = layout.intrinsicInsets
    }

    //  MARK: - Private Functions

    private func addControllerIfNeeded() {
        guard controller.parent == nil else {
            return
        }
        
        self.addChild(controller)
        self.displayNode.view.addSubview(controller.view)
        controller.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        controller.didMove(toParent: self)
    }
}
