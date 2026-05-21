import FeatDataSharing
import Postbox
import TelegramApi
import TelegramCore

extension Channel {
    static func build(
        peer: Peer?,
        channelFull: ChannelFull? = nil,
        icon: String? = nil,
        inviteLinks: [InviteLink] = [],
        messages: [FeatDataSharing.Message] = [],
        participantsCount: Int32? = nil,
        similarChannels: [Channel] = []
    ) throws -> Channel {
        let channel = try (peer as? TelegramChannel).unwrap()
        let flags = channel.flags
        
        let lastMessageLang = getLanguageCode(messages: messages)
        
        let type = switch channel.info {
        case .broadcast: "channel"
        case .group: "group"
        }
        
        let payload = ChannelPayload(
            about: channelFull?.about ?? "",
            date: channel.creationDate,
            fake: flags.contains(.isFake),
            geoLocation: channelFull?.geoLocation,
            gigagroup: flags.contains(.isGigagroup),
            hasGeo: flags.contains(.hasGeo),
            lastMessageLang: lastMessageLang,
            messages: prepareForSharing(messages: messages),
            participantsCount: channelFull?.participantsCount ?? participantsCount ?? 0,
            photo: .init(channel.photo),
            restrictions: .init(channel.restrictionInfo),
            scam: flags.contains(.isScam),
            title: channel.title,
            username: channel.username,
            usernames: .init(channel.usernames),
            verified: flags.contains(.isVerified)
        )
        
        return Channel(
            icon: icon,
            id: channel.id.ng_toInt64(),
            inviteLinks: inviteLinks,
            payload: payload,
            similarChannels: similarChannels,
            type: type
        )
    }
}

//  MARK: - ChannelFull

struct ChannelFull {
    let about: String?
    let geoLocation: GeoLocation?
    let participantsCount: Int32?
}

extension ChannelFull {
    init(_ api: ApiChatFullWrapped.ChannelFull) {
        self.init(
            about: api.about,
            geoLocation: .init(api.location),
            participantsCount: api.participantsCount
        )
    }
    
    init?(_ api: ApiChatFullWrapped.ChannelFull?) {
        guard let api else { return nil }
        self.init(api)
    }
}

extension ChannelFull {
    init(_ data: CachedChannelData) {
        self.init(
            about: data.about,
            geoLocation: .init(data.peerGeoLocation),
            participantsCount: data.participantsSummary.memberCount
        )
    }
    
    init?(_ data: CachedChannelData?) {
        guard let data else { return nil }
        self.init(data)
    }
}
