import AsyncDisplayKit
import Combine
import Factory
import FeatAttentionEconomy
import Postbox

public class SubscribeButtonClaimApplier {
    
    //  MARK: - Dependencies
    
    @Injected(\AttCoreModule.getOngoingActionsUseCase)
    private var getOngoingActionsUseCase
    
    //  MARK: - Logic
    
    private let claimView = AttClaimAnimationView()
    
    @Published public var showClaim = false
    
    @Published private var apply = true
    @Published private var chatId: PeerId? = nil
    @Published private var inviteHash: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    //  MARK: - Lifecycle
    
    public init() {
        getOngoingActionsUseCase.publisher()
            .combineLatestThreadSafe($apply, $chatId, $inviteHash)
            .map { actions, apply, chatId, inviteHash in
                guard apply else {
                    return false
                }
                
                let hasOngoingAction = actions.contains { action in
                    if case let .subscribe(subscribe) = action.type {
                        if let chatId, subscribe.chatId == chatId.ng_toInt64() {
                            return true
                        }
                        if let inviteHash, subscribe.inviteHash == inviteHash {
                            return true
                        }
                        return false
                    } else {
                        return false
                    }
                }
                return hasOngoingAction
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasOngoingAction in
                self?.showClaim = hasOngoingAction
            }
            .store(in: &cancellables)
        
        $showClaim
            .sink { [weak self] showClaim in
                self?.claimView.isHidden = !showClaim
            }
            .store(in: &cancellables)
    }
}

public extension SubscribeButtonClaimApplier {
    func update(
        buttonView: UIView,
        titleView: UIView,
        apply: Bool,
        chatId: PeerId?,
        inviteHash: String?
    ) {
        if claimView.superview == nil {
            buttonView.addSubview(claimView)
        }
        
        let size = CGSize(width: 20, height: 20)
        buttonView.layoutIfNeeded()
        claimView.frame = CGRect(
            x: titleView.frame.maxX + 5,
            y: titleView.frame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        if self.apply != apply {
            self.apply = apply
        }
        
        if self.chatId != chatId {
            self.chatId = chatId
        }
        
        if self.inviteHash != inviteHash {
            self.inviteHash = inviteHash
        }
    }
    
    func update(
        buttonNode: ASDisplayNode,
        titleNode: ASDisplayNode,
        apply: Bool,
        chatId: PeerId?,
        inviteHash: String?
    ) {
        update(
            buttonView: buttonNode.view,
            titleView: titleNode.view,
            apply: apply,
            chatId: chatId,
            inviteHash: inviteHash
        )
    }
}
