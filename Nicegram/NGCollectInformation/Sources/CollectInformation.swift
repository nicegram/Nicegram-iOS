import TelegramApi
import NaturalLanguage
import TelegramCore
import Combine
import AccountContext
import SwiftSignalKit
import Network
import MtProtoKit
import FeatCollectInformation
import NGUtils
import NGCore
import NGLogging

fileprivate let LOGTAG = extractNameFromPath(#file)
fileprivate let collectInformationContainer = CollectInformationContainer.shared
fileprivate let loadUseCase = collectInformationContainer.loadUseCase()
fileprivate let collectUseCase = collectInformationContainer.collectUseCase()

public func collectChannelsInformation(with context: AccountContext) {
    let collect = loadUseCase
        .publisher()
        .toSignal()
        .skipError()
    |> mapToSignal { result -> Signal<[(Api.contacts.ResolvedPeer?, ChannelInfo)], NoError> in
        resolveUsernames(with: context, informations: result)
    }
    |> mapToSignal { result -> Signal<[(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat])], NoError> in
        resolvedPeers(with: context, resolvedPeers: result)
    }
    |> mapToSignal { result -> Signal<Bool, NoError> in
        let models = result.compactMap { result -> FullInformation.Information? in
            switch result.0 {
            case let .chatFull(fullChat, chats, _):                
                let lastMessageLanguage = if let language = result.1 {
                    language
                } else {
                    ""
                }

                let icon: String = if case let .file(_, _, bytes) = result.2 {
                    bytes.makeData().base64EncodedString()
                } else {
                    ""
                }

                return mapToInformation(
                    with: fullChat,
                    chat: chats.first,
                    icon: icon,
                    lastMessageLanguage: lastMessageLanguage,
                    token: result.3.token,
                    similarChannels: result.4
                )
            default:
                return mapToInformation(with: result.3)
            }
        }
        guard !models.isEmpty else { return .single(false) }
    
        return collectUseCase
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
) -> Signal<[(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat])], NoError> {
    combineLatest(
        resolvedPeers
            .map { resolvedPeerResult -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
                guard let resolvedPeer = resolvedPeerResult.0 else
                    { return .single((nil, nil, nil, resolvedPeerResult.1, [])) }

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
                        return .single((nil, nil, nil, resolvedPeerResult.1, []))
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

private func lastMessageLanguageCode(
    with context: AccountContext,
    peer: Api.InputPeer
) -> Signal<String?, NoError> {
    context.account.network.request(Api.functions.messages.getHistory(
        peer: peer,
        offsetId: 0,
        offsetDate: 0,
        addOffset: 0,
        limit: 1,
        maxId: 0,
        minId: 0,
        hash: 0)
    )
    .skipError()
    |> map { result in
        var allMessages: [Api.Message] = []

        switch result {
        case let .channelMessages(_, _, _, _, messages, _, _, _):
            allMessages = messages
        case let .messages(messages, _, _):
            allMessages = messages
        case let .messagesSlice(_, _, _, _, messages, _, _):
            allMessages = messages
        case .messagesNotModified: break
        }
        
        let message = allMessages.compactMap {
            switch $0 {
            case let .message(_, _, _, _, _, _, _, _, _, _, _, _, message, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _):
                return message
            default: return nil
            }
        }.joined()
        
        return NLLanguageRecognizer.dominantLanguage(for: message)?.rawValue
    }
}

private func getFullChat(
    with context: AccountContext,
    id: Int64,
    accessHash: Int64,
    photo: Api.ChatPhoto,
    info: ChannelInfo
) -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> {
    context.account.network.request(Api.functions.messages.getFullChat(chatId: id))
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.ChatFull?, NoError> in
        ngLog("getFullChat id: \(id), error: \(error)", LOGTAG)
        return .single(nil)
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?), NoError> in
        lastMessageLanguageCode(
            with: context,
            peer: .inputPeerChat(chatId: id)
        )
        |> map {
            (result, $0)
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
        guard result.0 != nil else { return .single((result.0, result.1, nil, info, [])) }
        
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
                (result.0, result.1, $0, info, [])
            }
        default: return .single((nil, nil, nil, info, []))
        }
    }
}

private func getFullChannel(
    with context: AccountContext,
    id: Int64,
    accessHash: Int64,
    photo: Api.ChatPhoto,
    info: ChannelInfo
) -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> {
    context.account.network.request(Api.functions.channels.getFullChannel(
        channel: .inputChannel(channelId: id, accessHash: accessHash))
    )
    |> map(Optional.init)
    |> `catch` { error -> Signal<Api.messages.ChatFull?, NoError> in
        ngLog("getFullChannel id: \(id), error: \(error)", LOGTAG)
        return .single(nil)
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?), NoError> in
        lastMessageLanguageCode(
            with: context,
            peer: .inputPeerChannel(channelId: id, accessHash: accessHash)
        )
        |> map {
            (result, $0)
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo), NoError> in
        guard result.0 != nil else { return .single((result.0, result.1, nil, info)) }
        
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
                (result.0, result.1, $0, info)
            }
        default: return .single((nil, nil, nil, info))
        }
    }
    |> mapToSignal { result -> Signal<(Api.messages.ChatFull?, String?, Api.upload.File?, ChannelInfo, [Api.Chat]), NoError> in
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

            return (result.0, result.1, result.2, info, resultChats)
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
    similarChannels: [Api.Chat]
) -> FullInformation.Information {
    .init(
        chatFullModel: fullChat.toModel(),
        chatModel: chat?.toModel(),
        icon: icon,
        lastMessageLanguage: lastMessageLanguage,
        token: token,
        error: error,
        similarChannels: similarChannels.map { $0.toModel() }
    )
}

private func mapToInformation(
    with info: ChannelInfo,
    error: String = "NotFound"
) -> FullInformation.Information {
    .init(info: info, error: error)
}

private extension FullInformation.Information {
    init(
        info: ChannelInfo,
        error: String
    ) {
        self.init(
            id: 0,
            payload: .init(
                verified: false,
                scam: false,
                hasGeo: false,
                fake: false,
                megagroup: false,
                gigagroup: false,
                title: "",
                username: info.username,
                usernames: nil,
                date: 0,
                restrictions: [],
                participantsCount: nil,
                lastMessageLang: nil,
                about: nil,
                geoLocation: nil
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
        similarChannels: [Api.Chat.Model]
    ) {
        self.init(
            id: -(1000000000000 + (max(chatFullModel.id, chatModel?.id ?? 0))),
            payload: .init(
                verified: chatModel?.verified ?? false,
                scam: chatModel?.scam ?? false,
                hasGeo: chatModel?.hasGeo ?? false,
                fake: chatModel?.fake ?? false,
                megagroup: chatModel?.megagroup ?? false,
                gigagroup: chatModel?.gigagroup ?? false,
                title: chatModel?.title ?? "",
                username: chatModel?.username,
                usernames: chatModel?.usernames,
                date: chatModel?.date ?? 0,
                restrictions: chatModel?.restrictions ?? [],
                participantsCount: max(chatFullModel.participantsCount, chatModel?.participantsCount ?? 0),
                lastMessageLang: lastMessageLanguage,
                about: chatModel?.about ?? chatFullModel.about,
                geoLocation: chatFullModel.geoLocation
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

private extension FullInformation.Information.RecommendationInformation {
    init(
        chatModel: Api.Chat.Model
    ) {
        self.init(
            id: -(1000000000000 + chatModel.id),
            payload: .init(
                verified: chatModel.verified,
                scam: chatModel.scam,
                hasGeo: chatModel.hasGeo,
                fake: chatModel.fake,
                megagroup: chatModel.megagroup,
                gigagroup: chatModel.gigagroup,
                title: chatModel.title,
                username: chatModel.username,
                usernames: chatModel.usernames,
                date: chatModel.date,
                restrictions: chatModel.restrictions,
                participantsCount: chatModel.participantsCount,
                lastMessageLang: nil,
                about: chatModel.about,
                geoLocation: nil
            ),
            inviteLinks: [],
            icon: .init(
                id: chatModel.photoId,
                accessHash: chatModel.accessHash,
                flags: chatModel.flags,
                datacenterId: chatModel.datacenterId
            ),
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
        var restrictions = [FullInformation.Information.Payload.Restriction]()
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
            let restriction : [FullInformation.Information.Payload.Restriction] = restrictionReason?.map { reason -> FullInformation.Information.Payload.Restriction in
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
        var geoLocation: FullInformation.Information.Payload.GeoLocation?
        var inviteLinks = [FullInformation.Information.InviteLink]()
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
                    adminId: adminId,
                    date: date,
                    startDate: startDate,
                    expireDate: expireDate,
                    usageLimit: usageLimit,
                    requestedCount: requested
                )])
            default: break
            }
        }
        
        return model
    }
}
