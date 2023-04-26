import AccountContext
import UIKit
import Display

public class NativeControllerWrapper: ViewController {

    private let accountContext: AccountContext
    private let controller: UIViewController
    private var validLayout: ContainerViewLayout?

    public override var childForStatusBarStyle: UIViewController? {
        return controller
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return controller.supportedInterfaceOrientations
    }

    //  MARK: - Lifecycle

    public init(controller: UIViewController, accountContext: AccountContext) {
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
        controller.viewWillAppear(animated)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        controller.viewDidAppear(animated)
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        self.validLayout = layout
        let controllerFrame = CGRect(origin: CGPoint(), size: layout.size)

        if case .immediate = transition {
            self.controller.view.frame = controllerFrame
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.controller.view.frame = controllerFrame
            })
        }
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.nativeDismiss(animated: flag, completion: completion)
    }

    //  MARK: - Private Functions

    private func addControllerIfNeeded() {
        self.addChild(controller)
        self.displayNode.view.addSubview(controller.view)
        if let layout = self.validLayout {
            controller.view.frame = CGRect(origin: CGPoint(), size: layout.size)
        }
        controller.didMove(toParent: self)
    }
}
