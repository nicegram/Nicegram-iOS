import Foundation
import UIKit
import Display
import SwiftSignalKit
import AsyncDisplayKit
import TelegramPresentationData
import AccountContext
import TelegramUIPreferences
import TelegramCore

public func chatListFilterItems(context: AccountContext) -> Signal<(Int, [(ChatListFilter, Int, Bool)]), NoError> {
    return context.engine.peers.updatedChatListFilters()
    |> distinctUntilChanged
    |> mapToSignal { filters -> Signal<(Int, [(ChatListFilter, Int, Bool)]), NoError> in
        var unreadCountItems: [EngineRawUnreadMessageCountsItem] = []
        unreadCountItems.append(.totalInGroup(.root))
        var additionalPeerIds = Set<EnginePeer.Id>()
        var additionalGroupIds = Set<EnginePeerGroupId>()
        for case let .filter(_, _, _, data) in filters {
            additionalPeerIds.formUnion(data.includePeers.peers)
            additionalPeerIds.formUnion(data.excludePeers)
            if !data.excludeArchived {
                additionalGroupIds.insert(Namespaces.PeerGroup.archive)
            }
        }
        if !additionalPeerIds.isEmpty {
            for peerId in additionalPeerIds {
                unreadCountItems.append(.peer(id: peerId, handleThreads: true))
            }
        }
        for groupId in additionalGroupIds {
            unreadCountItems.append(.totalInGroup(groupId))
        }
        
        let globalNotificationsKey: EngineRawPostboxViewKey = .preferences(keys: Set([PreferencesKeys.globalNotifications]))
        let unreadKey: EngineRawPostboxViewKey = .unreadCounts(items: unreadCountItems)
        var keys: [EngineRawPostboxViewKey] = []
        keys.append(globalNotificationsKey)
        keys.append(unreadKey)
        for peerId in additionalPeerIds {
            keys.append(.basicPeer(peerId))
        }
        
        return context.account.postbox.combinedView(keys: keys)
        |> map { view -> (Int, [(ChatListFilter, Int, Bool)]) in
            guard let unreadCounts = view.views[unreadKey] as? EngineRawUnreadMessageCountsView else {
                return (0, [])
            }
            
            var globalNotificationSettings: GlobalNotificationSettingsSet
            if let settingsView = view.views[globalNotificationsKey] as? EngineRawPreferencesView, let settings = settingsView.values[PreferencesKeys.globalNotifications]?.get(GlobalNotificationSettings.self) {
                globalNotificationSettings = settings.effective
            } else {
                globalNotificationSettings = GlobalNotificationSettings.defaultSettings.effective
            }
            
            var result: [(ChatListFilter, Int, Bool)] = []
            
            var peerTagAndCount: [EnginePeer.Id: (EnginePeerSummaryCounterTags, Int, Bool, EnginePeerGroupId?, Bool)] = [:]
            
            var totalStates: [EnginePeerGroupId: EngineChatListTotalUnreadState] = [:]
            for entry in unreadCounts.entries {
                switch entry {
                case let .total(_, state):
                    totalStates[.root] = state
                case let .totalInGroup(groupId, state):
                    totalStates[groupId] = state
                case let .peer(peerId, state):
                    if let state = state, state.isUnread {
                        if let peerView = view.views[.basicPeer(peerId)] as? EngineRawBasicPeerView, let peer = peerView.peer {
                            let tag = context.account.postbox.seedConfiguration.peerSummaryCounterTags(peer, peerView.isContact)
                            
                            var peerCount = Int(state.count)
                            if state.isUnread {
                                peerCount = max(1, peerCount)
                            }
                            
                            var isMuted = false
                            if let notificationSettings = peerView.notificationSettings as? TelegramPeerNotificationSettings {
                                if case .muted = notificationSettings.muteState {
                                    isMuted = true
                                } else if case .default = notificationSettings.muteState {
                                    if let peer = peerView.peer {
                                        if peer is TelegramUser {
                                            isMuted = !globalNotificationSettings.privateChats.enabled
                                        } else if peer is TelegramGroup {
                                            isMuted = !globalNotificationSettings.groupChats.enabled
                                        } else if let channel = peer as? TelegramChannel {
                                            switch channel.info {
                                            case .group:
                                                isMuted = !globalNotificationSettings.groupChats.enabled
                                            case .broadcast:
                                                isMuted = !globalNotificationSettings.channels.enabled
                                            }
                                        }
                                    }
                                }
                            }
                            if isMuted {
                                peerTagAndCount[peerId] = (tag, peerCount, false, peerView.groupId, true)
                            } else {
                                peerTagAndCount[peerId] = (tag, peerCount, true, peerView.groupId, false)
                            }
                        }
                    }
                }
            }
            
            let totalBadge = 0
            
            for filter in filters {
                var count = 0
                var unmutedUnreadCount = 0
                if case let .filter(_, _, _, data) = filter {
                    var tags: [EnginePeerSummaryCounterTags] = []
                    if data.categories.contains(.contacts) {
                        tags.append(.contact)
                    }
                    if data.categories.contains(.nonContacts) {
                        tags.append(.nonContact)
                    }
                    if data.categories.contains(.groups) {
                        tags.append(.group)
                    }
                    if data.categories.contains(.bots) {
                        tags.append(.bot)
                    }
                    if data.categories.contains(.channels) {
                        tags.append(.channel)
                    }
                    
                    if let totalState = totalStates[.root] {
                        for tag in tags {
                            if data.excludeMuted {
                                if let value = totalState.filteredCounters[tag] {
                                    if value.chatCount != 0 {
                                        count += Int(value.chatCount)
                                        unmutedUnreadCount += Int(value.chatCount)
                                    }
                                }
                            } else {
                                if let value = totalState.absoluteCounters[tag] {
                                    count += Int(value.chatCount)
                                }
                                if let value = totalState.filteredCounters[tag] {
                                    if value.chatCount != 0 {
                                        unmutedUnreadCount += Int(value.chatCount)
                                    }
                                }
                            }
                        }
                    }
                    if !data.excludeArchived {
                        if let totalState = totalStates[Namespaces.PeerGroup.archive] {
                            for tag in tags {
                                if data.excludeMuted {
                                    if let value = totalState.filteredCounters[tag] {
                                        if value.chatCount != 0 {
                                            count += Int(value.chatCount)
                                            unmutedUnreadCount += Int(value.chatCount)
                                        }
                                    }
                                } else {
                                    if let value = totalState.absoluteCounters[tag] {
                                        count += Int(value.chatCount)
                                    }
                                    if let value = totalState.filteredCounters[tag] {
                                        if value.chatCount != 0 {
                                            unmutedUnreadCount += Int(value.chatCount)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    for peerId in data.includePeers.peers {
                        if let (tag, peerCount, hasUnmuted, groupIdValue, isMuted) = peerTagAndCount[peerId], peerCount != 0, let groupId = groupIdValue {
                            var matches = true
                            if tags.contains(tag) {
                                if isMuted && data.excludeMuted {
                                } else {
                                    matches = false
                                }
                            }
                            if matches {
                                let matchesGroup: Bool
                                switch groupId {
                                case .root:
                                    matchesGroup = true
                                case .group:
                                    if groupId == Namespaces.PeerGroup.archive {
                                        matchesGroup = !data.excludeArchived
                                    } else {
                                        matchesGroup = false
                                    }
                                }
                                if matchesGroup && peerCount != 0 {
                                    count += 1
                                    if hasUnmuted {
                                        unmutedUnreadCount += 1
                                    }
                                }
                            }
                        }
                    }
                    for peerId in data.excludePeers {
                        if let (tag, peerCount, _, groupIdValue, isMuted) = peerTagAndCount[peerId], peerCount != 0, let groupId = groupIdValue {
                            var matches = false
                            if tags.contains(tag) {
                                matches = true
                                if isMuted && data.excludeMuted {
                                    matches = false
                                }
                            }
                            
                            if matches {
                                let matchesGroup: Bool
                                switch groupId {
                                case .root:
                                    matchesGroup = true
                                case .group:
                                    if groupId == Namespaces.PeerGroup.archive {
                                        matchesGroup = !data.excludeArchived
                                    } else {
                                        matchesGroup = false
                                    }
                                }
                                if matchesGroup && peerCount != 0 {
                                    count -= 1
                                    if !isMuted {
                                        unmutedUnreadCount -= 1
                                    }
                                }
                            }
                        }
                    }
                }
                result.append((filter, max(0, count), unmutedUnreadCount > 0))
            }
            
            return (totalBadge, result)
        }
    }
}
