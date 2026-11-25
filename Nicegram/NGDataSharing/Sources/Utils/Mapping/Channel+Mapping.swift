import FeatDataSharing
import TelegramApi
import TelegramCore

extension Channel {
    static func build(
        peer: EngineRawPeer?,
        channelFull: ChannelFull? = nil,
        inviteLinks: [InviteLink] = [],
        messages: [FeatDataSharing.Message]? = nil,
        participantsCount: Int32? = nil,
        similarChannels: [Channel] = []
    ) throws -> Channel {
        let channel = try (peer as? TelegramChannel).unwrap()
        let flags = channel.flags
        
        let lastMessageLang = messages.flatMap { getLanguageCode(messages: $0) }
        
        let payload = ChannelPayload(
            about: channelFull?.about ?? "",
            date: channel.creationDate,
            fake: flags.contains(.isFake),
            geoLocation: channelFull?.geoLocation,
            gigagroup: flags.contains(.isGigagroup),
            hasGeo: flags.contains(.hasGeo),
            lastMessageLang: lastMessageLang,
            messages: messages,
            participantsCount: channelFull?.participantsCount ?? participantsCount ?? 0,
            restrictions: .init(channel.restrictionInfo),
            scam: flags.contains(.isScam),
            title: channel.title,
            username: channel.username,
            usernames: .init(channel.usernames),
            verified: flags.contains(.isVerified)
        )
        
        return Channel(
            id: channel.id.ng_toInt64(),
            inviteLinks: inviteLinks,
            payload: payload,
            similarChannels: similarChannels,
            type: Channel.Kind(channel.info)
        )
    }
}

extension Channel.Kind {
    init(_ info: TelegramChannelInfo) {
        switch info {
        case .broadcast: self = .channel
        case .group: self = .group
        }
    }
}

//  MARK: - ChannelFull

struct ChannelFull {
    let about: String?
    let geoLocation: GeoLocation?
    let participantsCount: Int32?
}

extension ChannelFull {
    init(_ api: Api.ChatFull.Cons_channelFull) {
        self.init(
            about: api.about,
            geoLocation: .init(api.location),
            participantsCount: api.participantsCount
        )
    }
    
    init?(_ api: Api.ChatFull.Cons_channelFull?) {
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
