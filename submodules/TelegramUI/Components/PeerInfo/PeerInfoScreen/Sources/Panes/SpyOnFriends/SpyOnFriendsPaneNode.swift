import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import AccountContext
import ContextUI
import PhotoResources
import TelegramUIPreferences
import ItemListPeerItem
import MergeLists
import ItemListUI
import ChatControllerInteraction
import PeerInfoVisualMediaPaneNode
import PeerInfoPaneNode
import FeatSpyOnFriends
import AvatarNode
import TelegramApi
import FeatSpyOnFriends
import NicegramWallet
import NGUtils

private struct SpyOnFriendsListTransaction {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
}

@available(iOS 15.0, *)
private enum SpyOnFriendsListEntry: Comparable, Identifiable {
    case header(sectionId: ItemListSectionId, context: SpyOnFriendsContext, count: Int)
    case group(sectionId: ItemListSectionId, context: AccountContext, group: (Date, [SpyOnFriendsGroup]))
    case unlock(sectionId: ItemListSectionId, context: SpyOnFriendsContext)
        
    var stableId: Int32 {
        switch self {
        case let .header(sectionId, _, _):
            return sectionId
        case let .group(sectionId, _, _):
            return sectionId
        case let .unlock(sectionId, _):
            return sectionId
        }
    }
    
    static func ==(lhs: SpyOnFriendsListEntry, rhs: SpyOnFriendsListEntry) -> Bool {
        switch lhs {
        case let .header(_, _, lhsCount):
            if case let .header(_, _, rhsCount) = rhs {
                return lhsCount == rhsCount
            } else {
                return false
            }
        case let .group(_, _, lhsGroups):
            if case let .group(_, _, rhsGroups) = rhs {
                return lhsGroups.0 == rhsGroups.0
            } else {
                return false
            }
        case let .unlock(lhsSectionId, _):
            if case let .unlock(rhsSectionId, _) = rhs {
                return lhsSectionId == rhsSectionId
            } else {
                return false
            }
        }
    }
    
    static func <(lhs: SpyOnFriendsListEntry, rhs: SpyOnFriendsListEntry) -> Bool {
        switch lhs {
            case let .group(_, _, lhsGroups):
                switch rhs {
                    case let .group(_, _, rhsGroups):
                    return lhsGroups.0 < rhsGroups.0
                case .header, .unlock:
                    return false
                }
        case .header, .unlock:
            return false
        }
    }
    
    func item(
        accountContext: AccountContext,
        peerId: PeerId,
        presentationData: PresentationData,
        openMessage: @escaping (Int32) -> Void
    ) -> ListViewItem {
        switch self {
        case let .header(sectionId, context, count):
            return SpyOnFriendsHeaderItem(
                sectionId: sectionId,
                context: context,
                theme: presentationData.theme,
                count: count,
                peerId: peerId.id._internalGetInt64Value()
            )
        case let .group(sectionId, context, group):
            return SpyOnFriendsMessagesItem(
                sectionId: sectionId,
                context: context,
                theme: presentationData.theme,
                group: group,
                openMessage: openMessage
            )
        case let .unlock(sectionId, context):
            return SpyOnFriendsUnlockItem(
                sectionId: sectionId,
                theme: presentationData.theme,
                context: context,
                accountContext: accountContext,
                peerId: peerId
            )
        }
    }
}

@available(iOS 15.0, *)
private func preparedTransition(
    from fromEntries: [SpyOnFriendsListEntry],
    to toEntries: [SpyOnFriendsListEntry],
    context: AccountContext,
    peerId: PeerId,
    presentationData: PresentationData,
    openMessage: @escaping (Int32) -> Void
) -> SpyOnFriendsListTransaction {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map {
        ListViewInsertItem(
            index: $0.0,
            previousIndex: $0.2,
            item: $0.1.item(accountContext: context, peerId: peerId, presentationData: presentationData, openMessage: openMessage),
            directionHint: nil
        )
    }
    let updates = updateIndices.map {
        ListViewUpdateItem(
            index: $0.0,
            previousIndex: $0.2,
            item: $0.1.item(accountContext: context, peerId: peerId, presentationData: presentationData, openMessage: openMessage),
            directionHint: nil)
    }
    
    return SpyOnFriendsListTransaction(deletions: deletions, insertions: insertions, updates: updates)
}

@available(iOS 15.0, *)
final class SpyOnFriendsPaneNode: ASDisplayNode, PeerInfoPaneNode {
    private let context: AccountContext
    private let peerId: PeerId
    private let chatControllerInteraction: ChatControllerInteraction
    private let openPeerContextAction: (Bool, Peer, ASDisplayNode, ContextGesture?) -> Void
    private let spyOnFriendsContext: SpyOnFriendsContext
    
    private let feature = SpyOnFriendsFeature(navigator: SpyOnFriendsNavigatorImpl())
    
    weak var parentController: ViewController?
    
    private let listNode: ListView
    private let coveringView: UIView
    private var state: SpyOnFriendsState?
    private var currentEntries: [SpyOnFriendsListEntry] = []
    private var enqueuedTransactions: [SpyOnFriendsListTransaction] = []
    
    private var currentParams: (size: CGSize, isScrollingLockedAtTop: Bool, presentationData: PresentationData)?
    
    private let ready = Promise<Bool>()
    private var didSetReady: Bool = false
    var isReady: Signal<Bool, NoError> {
        self.ready.get()
    }

    var status: Signal<PeerInfoStatusData?, NoError> {
        self.spyOnFriendsContext.state
        |> map { state in
            PeerInfoStatusData(text: "", isActivity: false, key: .spyOnFriends)
        }
    }

    var tabBarOffsetUpdated: ((ContainedViewLayoutTransition) -> Void)?
    var tabBarOffset: CGFloat { 0.0 }
        
    private var disposable: Disposable?
    
    init(
        context: AccountContext,
        peerId: PeerId,
        chatControllerInteraction: ChatControllerInteraction,
        openPeerContextAction: @escaping (Bool, Peer, ASDisplayNode, ContextGesture?) -> Void,
        spyOnFriendsContext: SpyOnFriendsContext
    ) {
        self.context = context
        self.peerId = peerId
        self.chatControllerInteraction = chatControllerInteraction
        self.openPeerContextAction = openPeerContextAction
        self.spyOnFriendsContext = spyOnFriendsContext
        
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.listNode = ListView()
        self.listNode.accessibilityPageScrolledString = { row, count in
            presentationData.strings.VoiceOver_ScrollStatus(row, count).string
        }
        
        self.listNode.backgroundColor = presentationData.theme.list.blocksBackgroundColor
        self.coveringView = UIView()
        
        super.init()
        
        self.listNode.preloadPages = true
        self.addSubnode(self.listNode)
        self.view.addSubview(self.coveringView)
        
        self.disposable = (spyOnFriendsContext.state
        |> deliverOnMainQueue).startStrict(next: { [weak self] state in
            guard let self else { return }
            
            self.state = state
            if let (_, _, presentationData) = self.currentParams {
                self.updateEntries(state: state, presentationData: presentationData)
            }
        })
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    func ensureMessageIsVisible(id: MessageId) {
    }
    
    func scrollToTop() -> Bool {
        if !self.listNode.scrollToOffsetFromTop(0.0, animated: true) {
            self.listNode.transaction(
                deleteIndices: [],
                insertIndicesAndItems: [],
                updateIndicesAndItems: [],
                options: [.Synchronous, .LowLatency],
                scrollToItem: ListViewScrollToItem(
                    index: 0,
                    position: .top(0.0),
                    animated: true,
                    curve: .Default(duration: nil),
                    directionHint: .Up
                ),
                updateSizeAndInsets: nil,
                stationaryItemRange: nil,
                updateOpaqueState: nil,
                completion: { _ in }
            )
            return true
        } else {
            return false
        }
    }
    
    func update(
        size: CGSize,
        topInset: CGFloat,
        sideInset: CGFloat,
        bottomInset: CGFloat,
        deviceMetrics: DeviceMetrics,
        visibleHeight: CGFloat,
        isScrollingLockedAtTop: Bool,
        expandProgress: CGFloat,
        navigationHeight: CGFloat,
        presentationData: PresentationData,
        synchronous: Bool,
        transition: ContainedViewLayoutTransition
    ) {
        let isFirstLayout = self.currentParams == nil
        self.currentParams = (size, isScrollingLockedAtTop, presentationData)
        
        self.coveringView.backgroundColor = presentationData.theme.list.itemBlocksBackgroundColor
        transition.updateFrame(view: self.coveringView, frame: CGRect(origin: CGPoint(x: 0.0, y: -1.0), size: CGSize(width: size.width, height: topInset + 1.0)))
        
        transition.updateFrame(node: self.listNode, frame: CGRect(origin: CGPoint(), size: size))
        let (duration, curve) = listViewAnimationDurationAndCurve(transition: transition)
        
        var scrollToItem: ListViewScrollToItem?
        if isScrollingLockedAtTop {
            switch self.listNode.visibleContentOffset() {
            case let .known(value) where value <= CGFloat.ulpOfOne:
                break
            default:
                scrollToItem = ListViewScrollToItem(
                    index: 0,
                    position: .top(0.0),
                    animated: true,
                    curve: .Spring(duration: duration),
                    directionHint: .Up
                )
            }
        }

        self.listNode.transaction(
            deleteIndices: [],
            insertIndicesAndItems: [],
            updateIndicesAndItems: [],
            options: [.Synchronous, .LowLatency],
            scrollToItem: scrollToItem,
            updateSizeAndInsets: ListViewUpdateSizeAndInsets(
                size: size,
                insets: UIEdgeInsets(top: topInset, left: sideInset, bottom: bottomInset, right: sideInset),
                duration: duration,
                curve: curve
            ),
            stationaryItemRange: nil,
            updateOpaqueState: nil,
            completion: { _ in }
        )
        
        self.listNode.scrollEnabled = !isScrollingLockedAtTop
        
        if isFirstLayout, let state = self.state {
            self.updateEntries(state: state, presentationData: presentationData)
        }
    }
    
    func transferVelocity(_ velocity: CGFloat) {
        if velocity > 0.0 {
            self.listNode.transferVelocity(velocity)
        }
    }

    func findLoadedMessage(id: MessageId) -> Message? {
       nil
    }
    
    func updateHiddenMedia() {}
        
    func cancelPreviewGestures() {}
    
    func transitionNodeForGallery(
        messageId: MessageId,
        media: Media
    ) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? { nil }
    
    func addToTransitionSurface(view: UIView) {}
    
    func updateSelectedMessages(animated: Bool) {}
    
    private func updateEntries(state: SpyOnFriendsState, presentationData: PresentationData) {
        var entries: [SpyOnFriendsListEntry] = [
            .header(sectionId: 0, context: spyOnFriendsContext, count: state.commonCount)
        ]
        
        if feature.getLastUpdated(with: peerId.id._internalGetInt64Value()) == nil {
            entries.append(.unlock(sectionId: 1, context: spyOnFriendsContext))
        }
        
        let groups = groups(from: state.chatsWithMessages)
        
        let groupsEntries = groups.map {
            SpyOnFriendsListEntry.group(
                sectionId: ItemListSectionId($0.0.timeIntervalSince1970),
                context: context,
                group: $0
            )
        }
        
        entries.append(contentsOf: groupsEntries)
        
        let transaction = preparedTransition(
            from: self.currentEntries,
            to: entries,
            context: self.context,
            peerId: self.peerId,
            presentationData: presentationData,
            openMessage: { [weak self] id in
                self?.openMessage(with: id)
            }
        )
        self.currentEntries = entries
        self.enqueuedTransactions.append(transaction)
        self.dequeueTransaction()
    }
    
    private func dequeueTransaction() {
        guard let _ = self.currentParams,
              let transaction = self.enqueuedTransactions.first else {
            return
        }
        
        self.enqueuedTransactions.remove(at: 0)
        
        var options = ListViewDeleteAndInsertOptions()
        options.insert(.Synchronous)
        
        self.listNode.transaction(
            deleteIndices: transaction.deletions,
            insertIndicesAndItems: transaction.insertions,
            updateIndicesAndItems: transaction.updates,
            options: options,
            updateSizeAndInsets: nil,
            updateOpaqueState: nil,
            completion: { [weak self] _ in
                guard let self else { return }
                if !self.didSetReady {
                    self.didSetReady = true
                    self.ready.set(.single(true))
                }
            })
    }
    
    private func openMessage(with id: Int32) {
        guard let navigationController = chatControllerInteraction.navigationController() else { return }
        
        let result = state?.chatsWithMessages.first(where: { element in
            element.1.contains(where: {
                $0.id.id == id
            })
        })
        
        if let message = result?.1.first(where: { $0.id.id == id }),
           let peerId = result?.0?.peerId,
           let peer = message.peers.first(where: { $0.0 == peerId }) {
            context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                navigationController: navigationController,
                context: context,
                chatLocation: .peer(EnginePeer(peer.1)),
                subject: .message(id: .id(message.id),
                                  highlight: ChatControllerSubject.MessageHighlight(quote: nil),
                                  timecode: nil,
                                  setupReply: false
                                 )
            ))
        }
    }

    private func groups(from input: [(Api.Chat?, [Message])]) -> [(Date, [SpyOnFriendsGroup])] {
        var groupedByDate = [Date: [SpyOnFriendsGroup]]()
        
        for (chat, messages) in input {
            guard let chat else { continue }
            
            var messageCount = 0
            let spyOnFriendsMessages = messages.compactMap {
                if !$0.text.isEmpty && messageCount < 5 {
                    messageCount += 1
                    return SpyOnFriendsMessage(
                        id: $0.id.id,
                        timestamp: $0.timestamp,
                        groupId: chat.peerId.toInt64(),
                        text: $0.text
                    )
                }
                return nil
            }
            
            let messagesGroupedByDate = Dictionary(grouping: spyOnFriendsMessages) {
                $0.timestamp.dateWithoutTime
            }
            
            for (date, messagesForDate) in messagesGroupedByDate {
                if messagesForDate.count > 0 {
                    var groupsForDate = groupedByDate[date] ?? []
                    
                    let group = SpyOnFriendsGroup(
                        id: chat.peerId.toInt64(),
                        title: chat.title ?? "",
                        date: date,
                        messages: messagesForDate.sorted(by: { $0.timestamp > $1.timestamp })
                    )
                    
                    groupsForDate.append(group)
                    groupsForDate.sort { ($0.messages.first?.timestamp ?? 0) > ($1.messages.first?.timestamp ?? 0) }
                    groupedByDate[date] = groupsForDate
                }
            }
        }
        
        
        return groupedByDate.sorted { $0.key > $1.key }
    }
}

@available(iOS 15.0, *)
public final class SpyOnFriendsHeaderItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let context: SpyOnFriendsContext
    public let theme: PresentationTheme
    public let count: Int
    public let peerId: Int64
    
    public init(
        sectionId: ItemListSectionId,
        context: SpyOnFriendsContext,
        theme: PresentationTheme,
        count: Int,
        peerId: Int64
    ) {
        self.sectionId = sectionId
        self.context = context
        self.theme = theme
        self.count = count
        self.peerId = peerId
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsHeaderNode(peerId: self.peerId)
            node.setupItem(self)

            let (layout, apply) = node.asyncLayout()(self, params, false, false, false)
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets

            completion(node, {
                return (nil, { _ in apply(.None) })
            })
        }
        if Thread.isMainThread {
            configure()
        } else {
            Queue.mainQueue().async(configure)
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? SpyOnFriendsHeaderNode {
                nodeValue.setupItem(self)
                
                let nodeLayout = nodeValue.asyncLayout()
                
                let (layout, apply) = nodeLayout(self, params, false, false, false)
                
                completion(layout, { _ in
                    apply(animation)
                })
            } else {
                assertionFailure()
            }
        }
    }
}

@available(iOS 15.0, *)
class SpyOnFriendsHeaderNode: ListViewItemNode {
    var item: SpyOnFriendsHeaderItem?

    private let headerView: SpyOnFriendsHeaderView
    private let headerNode: ASDisplayNode
    
    required init(peerId: Int64) {
        let headerView = SpyOnFriendsHeaderView(peerId: peerId)
        self.headerView = headerView
        self.headerNode = ASDisplayNode {
            headerView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)

        self.addSubnode(headerNode)
    }
    
    func setupItem(_ item: SpyOnFriendsHeaderItem) {
        self.item = item
        
        headerView.setup(
            with: item.count,
            accentColor: item.theme.list.itemAccentColor,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor
        ) {
            item.context.load()
        }
    }

    func asyncLayout() -> (_ item: SpyOnFriendsHeaderItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (
                    ListViewItemNodeLayout(
                        contentSize: .zero,
                        insets: .zero
                    ),
                    { _ in }
                )
            }

            headerView.setup(
                with: item.count,
                accentColor: item.theme.list.itemAccentColor,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor
            ) {
                item.context.load()
            }
            headerView.updateConstraintsIfNeeded()

            let headerInsets: UIEdgeInsets = isPortrait ? .vertical(12).horizontal(16) : .vertical(12).horizontal(59)
            let headerSize = headerView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width - (headerInsets.left + headerInsets.right),
                height: headerSize.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: headerInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                headerNode.frame = CGRect(origin: .init(x: headerInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
}

extension ListViewItemNode {
    var isPortrait: Bool {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation.isPortrait ?? false
    }
}

@available(iOS 15.0, *)
public final class SpyOnFriendsMessagesItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let context: AccountContext
    public let theme: PresentationTheme
    public let group: (Date, [SpyOnFriendsGroup])
    public let openMessage: (Int32) -> Void
    
    public init(
        sectionId: ItemListSectionId,
        context: AccountContext,
        theme: PresentationTheme,
        group: (Date, [SpyOnFriendsGroup]),
        openMessage: @escaping (Int32) -> Void
    ) {
        self.sectionId = sectionId
        self.context = context
        self.theme = theme
        self.group = group
        self.openMessage = openMessage
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsMessagesNode()
            node.setupItem(self)

            let (layout, apply) = node.asyncLayout()(self, params, false, false, false)
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets

            completion(node, {
                return (nil, { _ in apply(.None) })
            })
        }
        if Thread.isMainThread {
            configure()
        } else {
            Queue.mainQueue().async(configure)
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? SpyOnFriendsMessagesNode {
                nodeValue.setupItem(self)
                
                let nodeLayout = nodeValue.asyncLayout()
                
                let (layout, apply) = nodeLayout(self, params, false, false, false)
                
                completion(layout, { _ in
                    apply(animation)
                })
            } else {
                assertionFailure()
            }
        }
    }
}

@available(iOS 15.0, *)
class SpyOnFriendsMessagesNode: ListViewItemNode {
    var item: SpyOnFriendsMessagesItem?

    private let messagesView: SpyOnFriendsMessagesView
    private let messagesNode: ASDisplayNode

    required init() {
        let messagesView = SpyOnFriendsMessagesView()
        self.messagesView = messagesView
        self.messagesNode = ASDisplayNode {
            messagesView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)
        
        self.addSubnode(messagesNode)
    }
    
    func setupItem(_ item: SpyOnFriendsMessagesItem) {
        self.item = item
        
        messagesView.setup(
            with: item.group,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor,
            tapOnMessage: { id in
                item.openMessage(id)
            },
            logoLoader: { [weak self] peerId in
                guard let self else { return nil }
                
                return try await self.peerAvatar(with: item.context, peerId: PeerId(peerId)).awaitForFirstValue()
            }
        )
    }

    func asyncLayout() -> (_ item: SpyOnFriendsMessagesItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (
                    ListViewItemNodeLayout(
                        contentSize: .zero,
                        insets: .zero
                    ),
                    { _ in }
                )
            }
            
            messagesView.setup(
                with: item.group,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor,
                tapOnMessage: { id in
                    item.openMessage(id)
                },
                logoLoader: { [weak self] peerId in
                    guard let self else { return nil }
                    
                    return try await self.peerAvatar(with: item.context, peerId: PeerId(peerId)).awaitForFirstValue()
                }
            )
            messagesView.updateConstraintsIfNeeded()

            let messagesInsets: UIEdgeInsets = isPortrait ? .bottom(32).horizontal(16) : .bottom(32).horizontal(59)
            let messagesSize = messagesView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            let size = CGSize(
                width: params.width - (messagesInsets.left + messagesInsets.right),
                height: messagesSize.height
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: messagesInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                messagesNode.frame = CGRect(origin: .init(x: messagesInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }
    
    private func peerAvatar(with context: AccountContext, peerId: PeerId) -> Signal<UIImage?, NoError> {
        return context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<UIImage?, NoError> in
            guard let peer else { return .single(nil) }

            return peerAvatarCompleteImage(
                account: context.account,
                peer: peer,
                forceProvidedRepresentation: false,
                representation: nil,
                size: CGSize(width: 50, height: 50)
            )
        }
    }
}

@available(iOS 15.0, *)
public final class SpyOnFriendsUnlockItem: ListViewItem, ItemListItem {
    public let sectionId: ItemListSectionId
    public let theme: PresentationTheme
    public let context: SpyOnFriendsContext
    public let accountContext: AccountContext
    public let peerId: PeerId
    
    public init(
        sectionId: ItemListSectionId,
        theme: PresentationTheme,
        context: SpyOnFriendsContext,
        accountContext: AccountContext,
        peerId: PeerId
    ) {
        self.sectionId = sectionId
        self.theme = theme
        self.context = context
        self.accountContext = accountContext
        self.peerId = peerId
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        let configure = { () -> Void in
            let node = SpyOnFriendsUnlockNode(peerId: self.peerId.id._internalGetInt64Value())
            node.setupItem(self)

            let (layout, apply) = node.asyncLayout()(self, params, false, false, false)
            
            node.contentSize = layout.contentSize
            node.insets = layout.insets

            completion(node, {
                return (nil, { _ in apply(.None) })
            })
        }
        if Thread.isMainThread {
            configure()
        } else {
            Queue.mainQueue().async(configure)
        }
    }
    
    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? SpyOnFriendsUnlockNode {
                let nodeLayout = nodeValue.asyncLayout()
                
                let (layout, apply) = nodeLayout(self, params, false, false, false)
                
                completion(layout, { _ in
                    apply(animation)
                })
            } else {
                assertionFailure()
            }
        }
    }
}

@available(iOS 15.0, *)
class SpyOnFriendsUnlockNode: ListViewItemNode {
    var item: SpyOnFriendsUnlockItem?

    private let unlockView: SpyOnFriendsUnlockView
    private let unlockNode: ASDisplayNode
    
    required init(peerId: Int64) {
        let unlockView = SpyOnFriendsUnlockView(peerId: peerId)
        self.unlockView = unlockView
        self.unlockNode = ASDisplayNode {
            unlockView
        }

        super.init(layerBacked: false, dynamicBounce: false, rotated: false)
        
        self.addSubnode(unlockNode)
    }

    func setupItem(_ item: SpyOnFriendsUnlockItem) {
        self.item = item

        unlockView.setup(
            with: item.theme.list.itemAccentColor,
            backgroundColor: item.theme.list.itemBlocksBackgroundColor
        ) {
            item.context.load()
        } share: { [weak self] in
            self?.presentShare(with: item.peerId, context: item.accountContext)
        }
        unlockView.rotate()
    }

    func asyncLayout() -> (_ item: SpyOnFriendsUnlockItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { [weak self] item, params, mergedTop, mergedBottom, dateHeaderAtBottom -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) in
            guard let self else {
                return (
                    ListViewItemNodeLayout(
                        contentSize: .zero,
                        insets: .zero
                    ),
                    { _ in }
                )
            }

            unlockView.setup(
                with: item.theme.list.itemAccentColor,
                backgroundColor: item.theme.list.itemBlocksBackgroundColor
            ) {
                item.context.load()
            } share: { [weak self] in
                self?.presentShare(with: item.peerId, context: item.accountContext)
            }
            unlockView.rotate()
            unlockView.updateConstraintsIfNeeded()
            
            let unlockInsets: UIEdgeInsets = isPortrait ? .top(20).bottom(64).horizontal(16) : .top(20).bottom(32).horizontal(59)
            let unlockSize = unlockView.systemLayoutSizeFitting(
                UIView.layoutFittingExpandedSize
            )
            
            let size = CGSize(
                width: params.width - (unlockInsets.left + unlockInsets.right),
                height: unlockSize.height + unlockInsets.bottom
            )
            
            let layout = ListViewItemNodeLayout(
                contentSize: size,
                insets: unlockInsets
            )
            
            let apply: (ListViewItemUpdateAnimation) -> Void = { [weak self] _ in
                guard let self else { return }
                unlockNode.frame = CGRect(origin: .init(x: unlockInsets.left, y: 0), size: size)
            }
            
            return (layout, apply)
        }
    }

    private func presentShare(with peerId: PeerId, context: AccountContext) {
        Task {
            let sender = await ContactMessageSender()
            let text = await sender.nicegramReferralLink()
            if let contact = await WalletTgUtils.peerToWalletContact(id: peerId, context: context) {
                await sender.send(
                    contact: contact,
                    text: text,
                    showConfirmation: true
                )
            }
        }
    }
}

private extension Api.Chat {
    var peerId: PeerId {
        switch self {
            case let .chat(_, id, _, _, _, _, _, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .chatEmpty(id):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .chatForbidden(id, _):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .channel(_, _, id, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(id))
            case let .channelForbidden(_, id, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(id))
        }
    }
}

extension Int32 {
    var dateWithoutTime: Date {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let calendar = Calendar.current

        return calendar.startOfDay(for: date)
    }
}
