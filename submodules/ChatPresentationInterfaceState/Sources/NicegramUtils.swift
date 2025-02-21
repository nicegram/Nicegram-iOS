import AsyncDisplayKit
import Combine
import Factory
import FeatAttentionEconomy

public class SubscribeButtonClaimApplier {
    
    //  MARK: - Dependencies
    
    @Injected(\AttCoreModule.getOngoingActionsUseCase)
    private var getOngoingActionsUseCase
    
    //  MARK: - Logic
    
    private let claimView = AttClaimAnimationView()
    
    @Published private var apply = true
    @Published private var username = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    //  MARK: - Lifecycle
    
    public init() {
        getOngoingActionsUseCase.publisher()
            .combineLatestThreadSafe($apply, $username)
            .map { actions, apply, username in
                guard apply else {
                    return false
                }
                
                let hasOngoingAction = actions.contains { action in
                    if case let .subscribe(subscribe) = action.type,
                       subscribe.username == username {
                        true
                    } else {
                        false
                    }
                }
                return hasOngoingAction
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showClaim in
                self?.claimView.isHidden = !showClaim
            }
            .store(in: &cancellables)
    }
}

public extension SubscribeButtonClaimApplier {
    func update(
        buttonNode: ASDisplayNode,
        titleNode: ASDisplayNode,
        apply: Bool,
        interfaceState: ChatPresentationInterfaceState
    ) {
        if claimView.superview == nil {
            buttonNode.view.addSubview(claimView)
        }
        
        let size = CGSize(width: 20, height: 20)
        buttonNode.layoutIfNeeded()
        claimView.frame = CGRect(
            x: titleNode.frame.maxX + 5,
            y: titleNode.frame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        if self.apply != apply {
            self.apply = apply
        }
        
        let username = interfaceState.renderedPeer?.peer?.addressName ?? ""
        if self.username != username {
            self.username = username
        }
    }
}
