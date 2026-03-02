import AccountContext
import Foundation
import MemberwiseInit
import Postbox
import SwiftSignalKit
import TelegramApi
import TelegramBridge
import TelegramCore
import FeatUserArchetype
import NGCore

private extension UserMessagesHistoryProviderImpl {
    struct TelegramDialog {
        let peer: TelegramDialogPeer
        let name: String?
        let topMessageId: Int32
        let lastMessageDate: Int32
    }
    
    struct TelegramDialogMessage {
        let id: Int32
        let date: Int32
        let text: String
    }
    
    enum TelegramDialogPeer {
        case user(id: Int64, accessHash: Int64)
        case chat(id: Int64)
        case channel(id: Int64, accessHash: Int64)
        
        func inputPeer() -> Api.InputPeer {
            switch self {
            case let .user(id, accessHash):
                return .inputPeerUser(.init(userId: id, accessHash: accessHash))
                
            case let .chat(id):
                return .inputPeerChat(.init(chatId: id))
                
            case let .channel(id, accessHash):
                return .inputPeerChannel(.init(channelId: id, accessHash: accessHash))
            }
        }
    }
    
    struct DialogsPageOffset {
        let offsetDate: Int32
        let offsetId: Int32
        let offsetPeerId: TelegramDialogPeer?
        
        public static let initial = DialogsPageOffset(
            offsetDate: 0,
            offsetId: 0,
            offsetPeerId: nil
        )
    }
    
    struct DialogsPage {
        let dialogs: [TelegramDialog]
        let nextOffset: DialogsPageOffset?
    }
}

@MemberwiseInit(.public)
public class UserMessagesHistoryProviderImpl {
    @Init(.public) private let contextProvider: ContextProvider
    private let apiRequestInterval: Double = 0.1
}

extension UserMessagesHistoryProviderImpl: UserMessagesHistoryProvider {
    public func fetchUserMessagesHistory(formDate: Int32) async throws -> UserMessagesHistory {
        let dialogs = try await fetchUserDialogs()
        var result: [UserMessagesHistory.Dialog] = []
        
        let userContacts: Set<Int64> = try await fetchUserContacts()
        
        for dialog in dialogs {
            let messages = try await fetchUserMessagesFor(dialog, fromDate: formDate)
            
            guard !messages.isEmpty else {
                continue
            }
            
            let dialogType: UserMessagesHistory.DialogType = {
                switch dialog.peer {
                case .user(let id, _):
                    return userContacts.contains(id) ? .contact : .user
                case .chat, .channel:
                    return .group
                }
            }()
            
            result.append(
                .init(
                    name: dialog.name,
                    type: dialogType,
                    messages: messages.map {
                        UserMessagesHistory.Message(
                            date: $0.date,
                            text: $0.text
                        )
                    }
                )
            )
        }
        
        return UserMessagesHistory(dialogs: result)
    }
}

private extension UserMessagesHistoryProviderImpl {
    func fetchUserMessagesFor(
        _ dialog: TelegramDialog,
        fromDate: Int32
    ) async throws -> [TelegramDialogMessage] {
        
        var result: [TelegramDialogMessage] = []
        var offsetId: Int32 = 0
        let limit: Int32 = 100
        
        while true {
            let page = try await fetchUserMessagesFor(
                dialog: dialog,
                fromDate: fromDate,
                offsetId: offsetId,
                limit: limit
            )
            
            result.append(contentsOf: page)
            
            guard page.count == limit, let last = page.last else {
                break
            }
            
            offsetId = last.id
            try await Task.sleep(seconds: apiRequestInterval)
        }
        
        return result
    }
    
    func fetchUserMessagesFor(
        dialog: TelegramDialog,
        fromDate: Int32,
        offsetId: Int32,
        limit: Int32
    ) async throws -> [TelegramDialogMessage] {
        let context = try contextProvider.context().unwrap()
        
        let result: Api.messages.Messages = try await context.account.network.request(
            Api.functions.messages.search(
                flags: (1 << 0) | (1 << 1),
                peer: dialog.peer.inputPeer(),
                q: "",
                fromId: .inputPeerSelf,
                savedPeerId: nil,
                savedReaction: nil,
                topMsgId: dialog.topMessageId,
                filter: .inputMessagesFilterEmpty,
                minDate: fromDate,
                maxDate: 0,
                offsetId: offsetId,
                addOffset: 0,
                limit: limit,
                maxId: 0,
                minId: 0,
                hash: 0
            )
        )
            .awaitForFirstValue()
        
        let messages: [Api.Message]
        
        switch result {
        case let .channelMessages(data):
            messages = data.messages
        case let .messages(data):
            messages = data.messages
        case let .messagesSlice(data):
            messages = data.messages
        case .messagesNotModified:
            return []
        }
        
        return messages.compactMap { message in
            guard case let .message(data) = message,
                  !data.message.isEmpty
            else {
                return nil
            }
            
            return TelegramDialogMessage(id: data.id, date: data.date, text: data.message)
        }
    }
    
    func fetchUserDialogs() async throws -> [TelegramDialog] {
        var result: [TelegramDialog] = []
        var offset: DialogsPageOffset? = .initial
        
        while offset != nil {
            guard let currentOffset = offset else {
                break
            }
            
            let page = try await fetchDialogsPage(offset: currentOffset, limit: 100)
            
            result += page.dialogs
            offset = page.nextOffset
            
            if offset != nil {
                try await Task.sleep(seconds: apiRequestInterval)
            }
        }
        return result
    }
    
    func fetchUserContacts() async throws -> Set<Int64> {
        let context = try contextProvider.context().unwrap()
        let result: Api.contacts.Contacts = try await context.account.network.request(
            Api.functions.contacts.getContacts(hash: 0)
        ).awaitForFirstValue()
        
        let contactIds: Set<Int64>
        
        guard case let .contacts(data) = result else {
            throw UnexpectedError()
        }
        
        contactIds = Set(data.users.compactMap { user in
            if case let .user(u) = user { return u.id }
            return nil
        })
        
        return contactIds
    }
    
    func fetchDialogsPage(
        offset: DialogsPageOffset,
        limit: Int32
    ) async throws -> DialogsPage {
        let context = try contextProvider.context().unwrap()
        
        let result: Api.messages.Dialogs = try await context.account.network.request(
            Api.functions.messages.getDialogs(
                flags: 1 << 1,
                folderId: 0,
                offsetDate: offset.offsetDate,
                offsetId: offset.offsetId,
                offsetPeer: offset.offsetPeerId?.inputPeer() ?? .inputPeerEmpty,
                limit: limit,
                hash: 0
            )
        )
            .awaitForFirstValue()
        
        let dialogs: [Api.Dialog]
        let messages: [Api.Message]
        let chats: [Api.Chat]
        let users: [Api.User]
        
        switch result {
        case let .dialogs(data):
            dialogs = data.dialogs
            messages = data.messages
            chats = data.chats
            users = data.users
            
        case let .dialogsSlice(data):
            dialogs = data.dialogs
            messages = data.messages
            chats = data.chats
            users = data.users
            
        case .dialogsNotModified:
            return DialogsPage(dialogs: [], nextOffset: nil)
        }
        
        let usersById: [Int64: Api.User] =
        users.reduce(into: [:]) { dict, user in
            guard case let .user(data) = user else {
                return
            }
            dict[data.id] = user
        }
        
        let channelsById: [Int64: Api.Chat] =
        chats.reduce(into: [:]) { dict, chat in
            guard case let .channel(data) = chat else {
                return
            }
            dict[data.id] = chat
        }
        
        var messagesMap: [Int32: Api.Message] = [:]
        for message in messages {
            if case let .message(data) = message {
                messagesMap[data.id] = message
            }
        }
        
        var resultDialogs: [TelegramDialog] = []
        
        for dialog in dialogs {
            guard case let .dialog(dialogData) = dialog else {
                continue
            }
            
            guard
                let message = messagesMap[dialogData.topMessage],
                case let .message(messageData) = message
                    
            else {
                continue
            }
            
            guard let telegramPeer = mapPeer(dialogData.peer, users: usersById, channels: channelsById) else {
                continue
            }
            
            let telegramDialog = TelegramDialog(
                peer: telegramPeer,
                name: dialogDisplayTitle(peer: dialogData.peer, users: usersById, chats: channelsById),
                topMessageId: dialogData.topMessage,
                lastMessageDate: messageData.date
            )
            
            resultDialogs.append(telegramDialog)
        }
        
        let lastApiDialog = dialogs.last
        let nextOffset: DialogsPageOffset?
        
        if dialogs.count == limit, let lastApiDialog {
            if case let .dialog(dialogData) = lastApiDialog,
               let lastMessage = messagesMap[dialogData.topMessage],
               case let .message(messageData) = lastMessage {
                
                let peerForOffset = mapPeer(dialogData.peer, users: usersById, channels: channelsById)
                
                nextOffset = DialogsPageOffset(
                    offsetDate: messageData.date,
                    offsetId: dialogData.topMessage,
                    offsetPeerId: peerForOffset
                )
            } else {
                nextOffset = nil
            }
        } else {
            nextOffset = nil
        }
        
        return DialogsPage(
            dialogs: resultDialogs,
            nextOffset: nextOffset
        )
    }
    
    func mapPeer(
        _ peer: Api.Peer,
        users: [Int64: Api.User],
        channels: [Int64: Api.Chat]
    ) -> TelegramDialogPeer? {
        
        switch peer {
        case let .peerUser(userData):
            guard let user = users[userData.userId],
                  TelegramUser(user: user).botInfo == nil,
                  case let .user(userData) = user,
                  let accessHash = userData.accessHash
            else {
                return nil
            }
            
            return .user(id: userData.id, accessHash: accessHash)
            
        case let .peerChat(chatData):
            return .chat(id: chatData.chatId)
            
        case let .peerChannel(channelData):
            guard let channel = channels[channelData.channelId],
                  case let .channel(channelData) = channel,
                  let accessHash = channelData.accessHash
            else {
                return nil
            }
            
            return .channel(id: channelData.id, accessHash: accessHash)
        }
    }
    
    func dialogDisplayTitle(
        peer: Api.Peer,
        users: [Int64: Api.User],
        chats: [Int64: Api.Chat]
    ) -> String? {
        switch peer {
        case let .peerUser(userData):
            guard let user = users[userData.userId] else { return nil }
            let telegramUser = TelegramUser(user: user)
            return [telegramUser.firstName, telegramUser.lastName]
                .compactMap({ $0 })
                .joined(separator: " ")
            
        case let .peerChat(chatData):
            guard let chat = chats[chatData.chatId],
                  case let .chat(chatData) = chat
            else { return nil }
            return chatData.title
            
        case let .peerChannel(channelData):
            guard let channel = chats[channelData.channelId],
                  case let .channel(channelData) = channel
            else { return nil }
            return channelData.title
        }
    }
}
