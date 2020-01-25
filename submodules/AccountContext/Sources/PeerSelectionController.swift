import Foundation
import Display
import Postbox
import SwiftSignalKit


public struct NiceChatListNodePeersFilter: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let onlyPrivateChats = NiceChatListNodePeersFilter(rawValue: 1 << 0)
    public static let onlyGroups = NiceChatListNodePeersFilter(rawValue: 1 << 1)
    public static let onlyChannels = NiceChatListNodePeersFilter(rawValue: 1 << 3)
    public static let onlyBots = NiceChatListNodePeersFilter(rawValue: 1 << 4)
    public static let onlyNonMuted = NiceChatListNodePeersFilter(rawValue: 1 << 5)
    public static let onlyUnread = NiceChatListNodePeersFilter(rawValue: 1 << 6)
    // public static let onlyFavourites = NiceChatListNodePeersFilter(rawValue: 1 << 7)
    public static let onlyAdmin = NiceChatListNodePeersFilter(rawValue: 1 << 8)
    public static let onlyMissed = NiceChatListNodePeersFilter(rawValue: 1 << 9)
    
    public static let custom1 = NiceChatListNodePeersFilter(rawValue: 1 << 10)
    
    
    // DON'T BREAK UPGRADE FROM OLDER VERSIONS!, DON'T REMOVE OLD VALUES
    // SEE "let supportedFilters: [Int32]"
    public static let all: [NiceChatListNodePeersFilter] = [.onlyAdmin, .onlyBots, .onlyChannels, .onlyGroups, .onlyPrivateChats, .onlyUnread, .onlyNonMuted, .onlyMissed]//, .custom1]
}

public struct ChatListNodePeersFilter: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public static let onlyWriteable = ChatListNodePeersFilter(rawValue: 1 << 0)
    public static let onlyPrivateChats = ChatListNodePeersFilter(rawValue: 1 << 1)
    public static let onlyGroups = ChatListNodePeersFilter(rawValue: 1 << 2)
    public static let onlyChannels = ChatListNodePeersFilter(rawValue: 1 << 3)
    public static let onlyManageable = ChatListNodePeersFilter(rawValue: 1 << 4)
    
    public static let excludeSecretChats = ChatListNodePeersFilter(rawValue: 1 << 5)
    public static let excludeRecent = ChatListNodePeersFilter(rawValue: 1 << 6)
    public static let excludeSavedMessages = ChatListNodePeersFilter(rawValue: 1 << 7)
    
    public static let doNotSearchMessages = ChatListNodePeersFilter(rawValue: 1 << 8)
    public static let removeSearchHeader = ChatListNodePeersFilter(rawValue: 1 << 9)
    
    public static let excludeDisabled = ChatListNodePeersFilter(rawValue: 1 << 10)
    public static let includeSavedMessages = ChatListNodePeersFilter(rawValue: 1 << 11)
    
    public static let excludeChannels = ChatListNodePeersFilter(rawValue: 1 << 12)
}

public final class PeerSelectionControllerParams {
    public let context: AccountContext
    public let filter: ChatListNodePeersFilter
    public let hasContactSelector: Bool
    public let title: String?
    public let attemptSelection: ((Peer) -> Void)?
    
    public init(context: AccountContext, filter: ChatListNodePeersFilter = [.onlyWriteable], hasContactSelector: Bool = true, title: String? = nil, attemptSelection: ((Peer) -> Void)? = nil) {
        self.context = context
        self.filter = filter
        self.hasContactSelector = hasContactSelector
        self.title = title
        self.attemptSelection = attemptSelection
    }
}

public protocol PeerSelectionController: ViewController {
    var peerSelected: ((PeerId) -> Void)? { get set }
    var inProgress: Bool { get set }
}
