import TelegramApi
import NaturalLanguage
import TelegramCore
import Combine
import AccountContext
import SwiftSignalKit
import Network
import MtProtoKit
import NGUtils
import NGCore
import NGLogging
import FeatNicegramHub

fileprivate let LOGTAG = extractNameFromPath(#file)
fileprivate let nicegramHubContainer = NicegramHubContainer.shared
fileprivate let loadChannelsUseCase = nicegramHubContainer.loadChannelsUseCase()
fileprivate let shareChannelsUseCase = nicegramHubContainer.shareChannelsUseCase()

public func shareChannelsInformation(with context: AccountContext) {
    let collect = loadChannelsUseCase
        .publisher()
        .toSignal()
        .skipError()
    |> mapToSignal { result -> Signal<[(Api.contacts.ResolvedPeer?, ChannelInfo)], NoError> in
        resolveUsernames(with: context, informations: result)
    }
    |> mapToSignal { result -> Signal<[(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat])], NoError> in
        resolvedPeers(with: context, resolvedPeers: result)
    }
    |> mapToSignal { result -> Signal<Bool, NoError> in
        let models = result.compactMap { result -> FullChannelsInformation.Information? in
            switch result.0 {
            case let .chatFull(fullChat, chats, _):                
                let lastMessageLanguage = if let language = result.1 {
                    language
                } else {
                    ""
                }

                let icon: String = if case let .file(_, _, bytes) = result.3 {
                    bytes.makeData().base64EncodedString()
                } else {
                    ""
                }

                return mapToInformation(
                    with: fullChat,
                    chat: chats.first,
                    icon: icon,
                    lastMessageLanguage: lastMessageLanguage,
                    token: result.4.token,
                    similarChannels: result.5,
                    latestMessages: result.2
                )
            default:
                return mapToInformation(with: result.4)
            }
        }
        guard !models.isEmpty else { return .single(false) }
    
        return shareChannelsUseCase
            .publisher(with: .init(chats: models))
            .map { _ in true }
            .toSignal()
            .skipError()
    }
    
    _ = collect
        .start { error in
            ngLog("collect error: \(error)", LOGTAG)
        }
}

private func resolvedPeers(
    with context: AccountContext,
    resolvedPeers: [(Api.contacts.ResolvedPeer?, ChannelInfo)]
) -> Signal<[(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat])], NoError> {
    combineLatest(
        resolvedPeers
            .map { resolvedPeerResult -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
                guard let resolvedPeer = resolvedPeerResult.0 else
                    { return .single((nil, nil, [], nil, resolvedPeerResult.1, [])) }

                switch resolvedPeer {
                case let .resolvedPeer(_, chats, _):
                    let chat = chats.first
                    switch chat {
                    case let .channel(_, _, id, accessHash, _, _, photo, _, _, _, _, _, _, _, _,  _, _, _, _, _, _, _):
                        return getFullChannel(
                            with: context,
                            id: id,
                            accessHash: accessHash ?? 0,
                            photo: photo,
                            info: resolvedPeerResult.1
                        )
                    case let .chat(_, id, _, photo, _, _, _, _, _, _):
                        return getFullChat(
                            with: context,
                            id: id,
                            accessHash: 0,
                            photo: photo,
                            info: resolvedPeerResult.1
                        )
                    default:
                        return .single((nil, nil, [], nil, resolvedPeerResult.1, []))
                    }
                }
            }
    )
}

private func resolveUsernames(
    with context: AccountContext,
    informations: [ChannelInfo]
) -> Signal<[(Api.contacts.ResolvedPeer?, ChannelInfo)], NoError> {
    combineLatest(
        informations.map { info -> Signal<(Api.contacts.ResolvedPeer?, ChannelInfo), NoError> in
            return context.account.network.request(Api.functions.contacts.resolveUsername(
                flags: 0,
                username: info.username,
                referer: nil
            ))
            |> map(Optional.init)
            |> `catch` { error -> Signal<Api.contacts.ResolvedPeer?, NoError> in
                ngLog("resolveUsername username: \(info.username) error: \(error)", LOGTAG)
                return .single(nil)
            }
            |> map {
                ($0, info)
            }
        }
    )
}

private func lastMessages(
    with context: AccountContext,
    peer: Api.InputPeer
) -> Signal<[Api.Message], NoError> {
    context.account.network.request(Api.functions.messages.getHistory(peer: peer, offsetId: 0, offsetDate: 0, addOffset: 0, limit: 10, maxId: 0, minId: 0, hash: 0))
        .skipError()
    |> map { result in
        switch result {
        case let .channelMessages(_, _, _, _, messages, _, _, _):
            return messages
        case let .messages(messages, _, _):
            return messages
        case let .messagesSlice(_, _, _, _, messages, _, _):
            return messages
        default:
            return []
        }
    }
}

private func lastMessageLanguageCode(with messages: [Api.Message]) -> String? {
    let messages = messages.compactMap {
        switch $0 {
        case let .message(_, _, _, _, _, _, _, _, _, _, _, _, message, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
            message
        default:
            nil
        }
    }
    guard let message = messages.first(where: { $0.count >= 16 }) ?? messages.first(where: { !$0.isEmpty }) else { return nil }
    
    return NLLanguageRecognizer.dominantLanguage(for: message)?.rawValue
}

private func getFullChat(
    with context: AccountContext,
    id: Int64,
    accessHash: Int64,
    photo: Api.ChatPhoto,
    info: ChannelInfo
) -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> {
    context.account.network.request(Api.functions.messages.getFullChat(chatId: id))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.ChatFull?, NoError> in
        ngLog("getFullChat id: \(id), error: \(error)", LOGTAG)
        return .single(nil)
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, [Api.Message]), NoError> in
        lastMessages(with: context, peer: .inputPeerChat(chatId: id))
        |> map {
            (result, $0)
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
        let lastMessageLanguageCode = lastMessageLanguageCode(with: result.1)
        guard result.0 != nil else {
            return .single((result.0, lastMessageLanguageCode, result.1, nil, info, []))
        }
        
        switch photo {
        case let .chatPhoto(flags, photoId, _, dcId):
            return getFile(
                with: context.account.network,
                peer: .inputPeerChat(chatId: id),
                flags: flags,
                photoId: photoId,
                datacenterId: dcId,
                limit: 256*256
            )
            |> map(Optional.init)
            |> `catch` { error -> Signal<Api.upload.File?, NoError> in
                ngLog("getFile id: \(id), error: \(error)", LOGTAG)
                return .single(nil)
            }
            |> map {
                (result.0, lastMessageLanguageCode, result.1, $0, info, [])
            }
        default: return .single((nil, nil, [], nil, info, []))
        }
    }
}

private func getFullChannel(
    with context: AccountContext,
    id: Int64,
    accessHash: Int64,
    photo: Api.ChatPhoto,
    info: ChannelInfo
) -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> {
    context.account.network.request(Api.functions.channels.getFullChannel(
        channel: .inputChannel(channelId: id, accessHash: accessHash))
    )
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.ChatFull?, NoError> in
        ngLog("getFullChannel id: \(id), error: \(error)", LOGTAG)
        return .single(nil)
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, [Api.Message]), NoError> in
        lastMessages(with: context, peer: .inputPeerChannel(channelId: id, accessHash: accessHash))
        |> map {
            (result, $0)
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo), NoError> in
        let lastMessageLanguageCode = lastMessageLanguageCode(with: result.1)
        guard result.0 != nil else { return .single((result.0, lastMessageLanguageCode, result.1, nil, info)) }
        
        switch photo {
        case let .chatPhoto(flags, photoId, _, dcId):
            return getFile(
                with: context.account.network,
                peer: .inputPeerChannel(channelId: id, accessHash: accessHash),
                flags: flags,
                photoId: photoId,
                datacenterId: dcId,
                limit: 256*256
            )
            |> map(Optional.init)
            |> `catch` { error -> Signal<Api.upload.File?, NoError> in
                ngLog("getFile id: \(id), error: \(error)", LOGTAG)
                return .single(nil)
            }
            |> map {
                (result.0, lastMessageLanguageCode, result.1, $0, info)
            }
        default: return .single((nil, nil, [], nil, info))
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, [Api.Message], Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
        var flags: Int32 = 0
        flags |= (1 << 0)

        return context.account.network.request(Api.functions.channels.getChannelRecommendations(
            flags: flags,
            channel: .inputChannel(channelId: id, accessHash: accessHash)
        ))
        |> map(Optional.init)
        |> `catch` { error -> Signal<Api.messages.Chats?, NoError> in
            ngLog("getFile id: \(id), error: \(error)", LOGTAG)
            return .single(nil)
        }
        |> map {
            var resultChats: [Api.Chat] = []

            switch $0 {
            case let .chats(chats):
                resultChats = chats
            case let .chatsSlice(_, chats):
                resultChats = chats
            case .none:
                break
            }
            
            return (result.0, result.1, result.2, result.3, info, resultChats)
        }
    }
}

private func mapToInformation(
    with fullChat: Api.ChatFull,
    chat: Api.Chat?,
    icon: String,
    lastMessageLanguage: String,
    token: String,
    error: String = "",
    similarChannels: [Api.Chat],
    latestMessages: [Api.Message]
) -> FullChannelsInformation.Information {
    .init(
        chatFullModel: fullChat.toModel(),
        chatModel: chat?.toModel(),
        icon: icon,
        lastMessageLanguage: lastMessageLanguage,
        token: token,
        error: error,
        similarChannels: similarChannels.map { $0.toModel() },
        latestMessages: latestMessages
    )
}

private func mapToInformation(
    with info: ChannelInfo,
    error: String = "NotFound"
) -> FullChannelsInformation.Information {
    .init(info: info, error: error)
}

private extension FullChannelsInformation.Information {
    init(
        info: ChannelInfo,
        error: String
    ) {
        self.init(
            id: 0,
            payload: ChannelPayload(
                verified: false,
                scam: false,
                hasGeo: false,
                fake: false,
                gigagroup: false,
                title: "",
                username: info.username,
                usernames: nil,
                date: 0,
                restrictions: [],
                participantsCount: nil,
                photo: nil,
                lastMessageLang: nil,
                about: nil,
                geoLocation: nil,
                messages: nil
            ),
            inviteLinks: [],
            icon: "",
            type: "channel",
            token: info.token,
            error: error,
            similarChannels: []
        )
    }
    
    init(
        chatFullModel: Api.ChatFull.Model,
        chatModel: Api.Chat.Model?,
        icon: String,
        lastMessageLanguage: String,
        token: String,
        error: String,
        similarChannels: [Api.Chat.Model],
        latestMessages: [Api.Message]
    ) {
        self.init(
            id: -(1000000000000 + (max(chatFullModel.id, chatModel?.id ?? 0))),
            payload: ChannelPayload(
                verified: chatModel?.verified ?? false,
                scam: chatModel?.scam ?? false,
                hasGeo: chatModel?.hasGeo ?? false,
                fake: chatModel?.fake ?? false,
                gigagroup: chatModel?.gigagroup ?? false,
                title: chatModel?.title ?? "",
                username: chatModel?.username,
                usernames: chatModel?.usernames,
                date: chatModel?.date ?? 0,
                restrictions: chatModel?.restrictions ?? [],
                participantsCount: max(chatFullModel.participantsCount, chatModel?.participantsCount ?? 0),
                photo: .init(
                    mediaResourceId: nil,
                    datacenterId: Int(chatModel?.datacenterId ?? 0),
                    photoId: chatModel?.photoId,
                    volumeId: nil,
                    localId: nil,
                    sizeSpec: nil,
                    accessHash: chatModel?.accessHash
                ),
                lastMessageLang: lastMessageLanguage,
                about: chatModel?.about ?? chatFullModel.about,
                geoLocation: chatFullModel.geoLocation,
                messages: latestMessages.compactMap(\.messageInformation)
            ),
            inviteLinks: chatFullModel.inviteLinks,
            icon: icon,
            type: chatModel?.type ?? "",
            token: token,
            error: error,
            similarChannels: similarChannels.map { .init(chatModel: $0) }
        )
    }
}

private extension FullChannelsInformation.Information.RecommendationInformation {
    init(
        chatModel: Api.Chat.Model
    ) {
        self.init(
            id: -(1000000000000 + chatModel.id),
            payload: ChannelPayload(
                verified: chatModel.verified,
                scam: chatModel.scam,
                hasGeo: chatModel.hasGeo,
                fake: chatModel.fake,
                gigagroup: chatModel.gigagroup,
                title: chatModel.title,
                username: chatModel.username,
                usernames: chatModel.usernames,
                date: chatModel.date,
                restrictions: chatModel.restrictions,
                participantsCount: chatModel.participantsCount,
                photo: .init(
                    mediaResourceId: nil,
                    datacenterId: Int(chatModel.datacenterId),
                    photoId: chatModel.photoId,
                    volumeId: nil,
                    localId: nil,
                    sizeSpec: nil,
                    accessHash: chatModel.accessHash
                ),
                lastMessageLang: nil,
                about: chatModel.about,
                geoLocation: nil,
                messages: nil
            ),
            inviteLinks: [],
            type: chatModel.type
        )
    }
}

private extension Api.Chat {
    struct Model: Withable {
        var verified: Bool = false
        var scam: Bool = false
        var hasGeo: Bool = false
        var fake: Bool = false
        var gigagroup: Bool = false
        var megagroup: Bool = false
        var date: Int32 = 0
        var participantsCount: Int32 = 0
        var id: Int64 = 0
        var username: String = ""
        var usernames: [String] = []
        var title: String = ""
        var about: String = ""
        var restrictions = [RestrictionPolicy]()
        var type: String = ""
        var accessHash: Int64? = nil
        var flags: Int32 = 0
        var photoId: Int64 = 0
        var datacenterId: Int32 = 0

        init () {}
    }
    
    func toModel() -> Model {
        var model = Model()
        if let channel = peer(with: self) as? TelegramChannel {
            let isGigagroup = channel.flags.contains(.isGigagroup)
            let isMegagroup = channel.flags.contains(.isMegagroup)
            let type = isGigagroup || isMegagroup ? "group" : "channel"
            
            model = model
                .with(\.type, type)
                .with(\.verified, channel.flags.contains(.isVerified))
                .with(\.scam, channel.flags.contains(.isScam))
                .with(\.hasGeo, channel.flags.contains(.hasGeo))
                .with(\.fake, channel.flags.contains(.isFake))
                .with(\.gigagroup, isGigagroup)
                .with(\.megagroup, isMegagroup)
                .with(\.usernames, channel.usernames.compactMap { $0.isActive ? $0.username : nil })
        } else {
            model = model
                .with(\.type, "group")
        }

        switch self {
        case let .channel(_, _, id, accessHash, title, username, photo, date, restrictionReason, _, _, _, participantsCount, _, _, _, _, _, _, _, _, _):
            let restriction : [RestrictionPolicy] = restrictionReason?.map { reason -> RestrictionPolicy in
                switch reason {
                case let .restrictionReason(platform, reason, text):
                    return .init(platform: platform, reason: reason, text: text)
                }
            } ?? []
            
            model = model
                .with(\.id, id)
                .with(\.title, title)
                .with(\.username, username ?? "")
                .with(\.date, date)
                .with(\.participantsCount, participantsCount ?? 0)
                .with(\.restrictions, restriction)
                .with(\.accessHash, accessHash)
            
            switch photo {
            case let .chatPhoto(flags, photoId, _, dcId):
                model = model
                    .with(\.flags, flags)
                    .with(\.photoId, photoId)
                    .with(\.datacenterId, dcId)
            default: break
            }

        case let .chat(_, id, title, photo, participantsCount, date, _, _, _, _):
            model = model
                .with(\.id, id)
                .with(\.title, title)
                .with(\.date, date)
                .with(\.participantsCount, participantsCount)
            
            switch photo {
            case let .chatPhoto(flags, photoId, _, dcId):
                model = model
                    .with(\.flags, flags)
                    .with(\.photoId, photoId)
                    .with(\.datacenterId, dcId)
            default: break
            }
        default: break
        }
        
        return model
    }
}

private extension Api.ChatFull {
    struct Model: Withable {
        var id: Int64 = 0
        var participantsCount: Int32 = 0
        var about: String = ""
        var geoLocation: GeoLocation?
        var inviteLinks = [InviteLink]()
        init () {}
    }

    func toModel() -> Model {
        var model = Model()
        switch self {
        case let .channelFull(_, _, id, about, participantsCount, _, _, _, _, _, _, _, _, _, _, _,  _, _, _, _, _, _, _, location, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
            model = model
                .with(\.id, id)
                .with(\.participantsCount, participantsCount ?? 0)
                .with(\.about, about)
            switch location {
            case let .channelLocation(geoPoint, address):
                switch geoPoint {
                case let .geoPoint(_, long, lat, _, _):
                    model = model.with(\.geoLocation, .init(latitude: lat, longitude: long, address: address))
                default: break
                }
            default: break
            }
        case let .chatFull(_, id, about, participants, _, _, exportedInvite, _, _, _, _, _, _, _, _, _, _, _):
            model = model
                .with(\.id, id)
                .with(\.about, about)

            switch participants {
            case let .chatParticipants(_, participants, _):
                model = model.with(\.participantsCount, Int32(participants.count))
            default: break
            }
            switch exportedInvite {
            case let .chatInviteExported(_, link, adminId, date, startDate, expireDate, usageLimit, _, requested, _, title, _):
                model = model.with(\.inviteLinks, [.init(
                    link: link,
                    title: title,
                    isPermanent: false,
                    requestApproval: false,
                    isRevoked: false,
                    adminId: adminId,
                    date: date,
                    startDate: startDate,
                    expireDate: expireDate,
                    usageLimit: usageLimit,
                    count: requested,
                    requestedCount: requested
                )])
            default: break
            }
        }
        
        return model
    }
}

extension Api.Message {
    var messageInformation: MessageInformation? {
        switch self {
        case let .message(_, _, id, fromId, _, peerId, _, _, _, _, _, date, message, media, _, _, views, _, replies, _, _, _, reactions, _, _, _, _, _, _, _):
            let commentsCount: Int32? = switch replies {
            case let .messageReplies(_, replies, _, _, _, _, _): replies
            default: nil
            }
            
            let authorId: Int64? = switch fromId {
            case let .peerChannel(channelId): channelId
            case let .peerChat(chatId): chatId
            case let .peerUser(userId): userId
            default: nil
            }
            
            let peerId: Int64 = switch peerId {
            case let .peerChannel(channelId): channelId
            case let .peerChat(chatId): chatId
            case let .peerUser(userId): userId
            }
            
            let reactions: [MessageInformation.Reaction]? = switch reactions {
            case let .messageReactions(_, results, _, _):
                results.compactMap {
                    switch $0 {
                    case let .reactionCount(_, _, reaction, count):
                        switch reaction {
                        case let .reactionCustomEmoji(documentId):
                            return MessageInformation.Reaction.customEmoji(documentId: documentId, count: count)
                        case let .reactionEmoji(emoticon):
                            return MessageInformation.Reaction.emoji(emoticon: emoticon, count: count)
                        case .reactionPaid:
                            return MessageInformation.Reaction.paid(count: count)
                        default:
                            return nil
                        }
                    }
                }
            default: nil
            }

            var messageMedia = [MessageInformation.Media]()
            switch media {
            case let .messageMediaDocument(_, document, _, _, _, _):
                switch document {
                case let .document(_, _, _, _, _, _, _, _, _, _, attributes):
                    attributes.forEach {
                        switch $0 {
                        case let .documentAttributeAudio(_, duration, title, _, _):
                            messageMedia.append(MessageInformation.Media.audio(duration: duration, title: title))
                        case let .documentAttributeVideo(_, duration, _, _, _, _, _):
                            messageMedia.append(MessageInformation.Media.video(duration: duration))
                        default:
                            break
                        }
                    }
                default: break
                }
            case let .messageMediaPhoto(_, photo, _):
                switch photo {
                case let .photo(_, id, accessHash, _, _, _, _, dcId):
                    messageMedia.append(MessageInformation.Media.photo(id: id, accessHash: accessHash, dcId: dcId))
                default: break
                }
            default: break
            }

            return MessageInformation(
                id: id,
                text: message,
                commentsCount: commentsCount,
                viewsCount: views,
                date: date,
                authorId: authorId,
                peerId: peerId,
                reactions: reactions,
                media: messageMedia
            )
        default:
            return nil
        }
    }
}
