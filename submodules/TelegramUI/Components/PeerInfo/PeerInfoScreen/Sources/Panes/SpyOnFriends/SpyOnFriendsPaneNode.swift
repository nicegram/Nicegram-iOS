import AsyncDisplayKit
import Display
import TelegramCore
import SwiftSignalKit
import Postbox
import TelegramPresentationData
import AccountContext
import MergeLists
import ItemListUI
import ChatControllerInteraction
import PeerInfoPaneNode
import FeatSpyOnFriends
import TelegramApi
import TelegramStringFormatting
import NicegramWallet
import NGUtils
import NGData

private struct SpyOnFriendsListTransaction {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
}

@available(iOS 15.0, *)
private enum SpyOnFriendsListEntry: Comparable, Identifiable {
    case header(sectionId: ItemListSectionId, context: SpyOnFriendsContext, isRefreshing: Bool)
    case group(sectionId: ItemListSectionId, context: AccountContext, group: (Date, [SpyOnFriendsGroup]))
    case unlock(sectionId: ItemListSectionId, context: SpyOnFriendsContext)
    case emptyData(sectionId: ItemListSectionId)
        
    var stableId: Int32 {
        switch self {
        case let .header(sectionId, _, _):
            return sectionId
        case let .group(sectionId, _, _):
            return sectionId
        case let .unlock(sectionId, _):
            return sectionId
        case let .emptyData(sectionId):
            return sectionId
        }
    }
    
    static func ==(lhs: SpyOnFriendsListEntry, rhs: SpyOnFriendsListEntry) -> Bool {
        switch lhs {
        case let .header(_, _, lhsIsRefreshing):
            if case let .header(_, _, rhsIsRefreshing) = rhs {
                return lhsIsRefreshing == rhsIsRefreshing
            } else {
                return false
            }
        case let .group(_, _, lhsGroups):
            if case let .group(_, _, rhsGroups) = rhs {
                return lhsGroups.1.elementsEqual(rhsGroups.1)
            } else {
                return false
            }
        case let .unlock(lhsSectionId, _):
            if case let .unlock(rhsSectionId, _) = rhs {
                return lhsSectionId == rhsSectionId
            } else {
                return false
            }
        case .emptyData:
            return true
        }
    }
    
    static func <(lhs: SpyOnFriendsListEntry, rhs: SpyOnFriendsListEntry) -> Bool {
        switch lhs {
            case let .group(_, _, lhsGroups):
                switch rhs {
                    case let .group(_, _, rhsGroups):
                    return lhsGroups.0 < rhsGroups.0
                case .header, .unlock, .emptyData:
                    return false
                }
        case .header, .unlock, .emptyData:
            return false
        }
    }
    
    func item(
        accountContext: AccountContext,
        peerId: PeerId,
        presentationData: PresentationData,
        openMessage: @escaping (Int32) -> Void,
        share: @escaping () -> Void
    ) -> ListViewItem {
        switch self {
        case let .header(sectionId, context, isRefreshing):
            return SpyOnFriendsHeaderItem(
                sectionId: sectionId,
                context: context,
                theme: presentationData.theme,
                locale: localeWithStrings(presentationData.strings),
                peerId: peerId.id._internalGetInt64Value(),
                isRefreshing: isRefreshing
            )
        case let .group(sectionId, context, group):
            return SpyOnFriendsMessagesItem(
                sectionId: sectionId,
                context: context,
                theme: presentationData.theme,
                locale: localeWithStrings(presentationData.strings),
                group: group,
                openMessage: openMessage
            )
        case let .unlock(sectionId, context):
            return SpyOnFriendsUnlockItem(
                sectionId: sectionId,
                theme: presentationData.theme,
                locale: localeWithStrings(presentationData.strings),
                context: context,
                accountContext: accountContext,
                peerId: peerId,
                share: share
            )
        case let .emptyData(sectionId):
            return SpyOnFriendsEmptyDataItem(
                sectionId: sectionId,
                theme: presentationData.theme
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
    openMessage: @escaping (Int32) -> Void,
    share: @escaping () -> Void
) -> SpyOnFriendsListTransaction {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)

    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map {
        ListViewInsertItem(
            index: $0.0,
            previousIndex: $0.2,
            item: $0.1.item(
                accountContext: context,
                peerId: peerId,
                presentationData: presentationData,
                openMessage: openMessage,
                share: share
            ),
            directionHint: nil
        )
    }
    let updates = updateIndices.map {
        ListViewUpdateItem(
            index: $0.0,
            previousIndex: $0.2,
            item: $0.1.item(
                accountContext: context,
                peerId: peerId,
                presentationData: presentationData,
                openMessage: openMessage,
                share: share
            ),
            directionHint: nil)
    }
    
    return SpyOnFriendsListTransaction(deletions: deletions, insertions: insertions, updates: updates)
}

@available(iOS 15.0, *)
final class SpyOnFriendsPaneNode: ASDisplayNode, PeerInfoPaneNode {
    private let context: AccountContext
    private let peerId: PeerId
    private let chatControllerInteraction: ChatControllerInteraction
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
        spyOnFriendsContext: SpyOnFriendsContext
    ) {
        self.context = context
        self.peerId = peerId
        self.chatControllerInteraction = chatControllerInteraction
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
        var entries: [SpyOnFriendsListEntry] = []
        
        if isPremium() || isPremiumPlus() {
            entries.append(.header(
                sectionId: 0,
                context: spyOnFriendsContext,
                isRefreshing: state.dataState != .ready(canLoadMore: true)
            ))
            
            let groups = groups(from: state.chatsWithMessages)
            
            if groups.isEmpty &&
                state.dataState == .ready(canLoadMore: true)  {
                entries.append(.emptyData(sectionId: 3))
            } else {
                let groupsEntries = groups.map {
                    SpyOnFriendsListEntry.group(
                        sectionId: ItemListSectionId($0.0.timeIntervalSince1970),
                        context: context,
                        group: $0
                    )
                }
                
                entries.append(contentsOf: groupsEntries)
            }
        } else {
            entries = [.unlock(sectionId: 1, context: spyOnFriendsContext)]
        }
                
        let transaction = preparedTransition(
            from: self.currentEntries,
            to: entries,
            context: self.context,
            peerId: self.peerId,
            presentationData: presentationData,
            openMessage: { [weak self] id in
                self?.openMessage(with: id)
            }, share: { [weak self] in
                self?.share()
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
                                 ),
                keepStack: .always
            ))
        }
    }
    
    private func share() {
        let controller = context.sharedContext.makePeerSelectionController(.init(
            context: context,
            filter: [.onlyWriteable, .excludeDisabled, .excludeBots],
            title: ""
        ))
        controller.navigationPresentation = .modal
        controller.peerSelected = { [weak self, weak controller] peer, _ in
            guard let self else { return }

            Task {
                let sender = await ContactMessageSender()
                let text = await sender.nicegramReferralLink()
                
                if let contact = await WalletTgUtils.peerToWalletContact(id: peer.id, context: self.context) {
                    await sender.send(
                        contact: contact,
                        text: text,
                        showConfirmation: true
                    )
                    await controller?.dismiss()
                }
            }

        }
        
        guard let navigationController = chatControllerInteraction.navigationController() else { return }
        navigationController.pushViewController(controller)
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

private extension Api.Chat {
    var peerId: PeerId {
        switch self {
            case let .chat(_, id, _, _, _, _, _, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .chatEmpty(id):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .chatForbidden(id, _):
                return PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(id))
            case let .channel(_, _, id, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(id))
            case let .channelForbidden(_, id, _, _, _):
                return PeerId(namespace: Namespaces.Peer.CloudChannel, id: PeerId.Id._internalFromInt64Value(id))
        }
    }
}

extension ListViewItemNode {
    var isPortrait: Bool {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation.isPortrait ?? false
    }
}

extension Int32 {
    var dateWithoutTime: Date {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let calendar = Calendar.current

        return calendar.startOfDay(for: date)
    }
}
