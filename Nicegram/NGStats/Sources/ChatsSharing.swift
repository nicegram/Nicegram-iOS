import AccountContext
import FeatNicegramHub
import Foundation
import NGUtils
import Postbox
import SwiftSignalKit
import TelegramCore

@available(iOS 13.0, *)
public func sharePeerData(
    peerId: PeerId,
    context: AccountContext
) {
    let _ = context.engine.peers.requestRecommendedChannels(peerId: peerId, forceUpdate: true).startStandalone()
    _ = (context.account.viewTracker.peerView(peerId, updateData: true)
    |> take(1))
    .start(next: { peerView in
        if let peer = peerView.peers[peerView.peerId] {
            Task {
                await sharePeerData(
                    peer: peer,
                    cachedData: peerView.cachedData,
                    context: context
                )
            }
        }
    })
}

@available(iOS 13.0, *)
private func sharePeerData(
    peer: Peer,
    cachedData: CachedPeerData?,
    context: AccountContext
) async {
    let peerId = extractPeerId(peer: peer)
    
    let type: PeerType
    switch EnginePeer(peer) {
    case let .channel(channel):
        switch channel.info {
        case .group:
            type = .group
        case .broadcast:
            type = .channel
        }
    case .legacyGroup:
        type = .group
    case .user(let user):
        if user.botInfo != nil {
            type = .bot
        } else {
            return
        }
    default:
        return
    }

    let sharePeerDataUseCase = NicegramHubContainer.shared.sharePeerDataUseCase()
    
    await sharePeerDataUseCase(
        id: peerId,
        participantsCount: extractParticipantsCount(
            peer: peer,
            cachedData: cachedData
        ),
        type: type,
        peerDataProvider: {
            await withCheckedContinuation { continuation in
                let avatarImageSignal = fetchAvatarImage(peer: peer, context: context)
                let inviteLinksSignal = context.engine.peers.direct_peerExportedInvitations(peerId: peer.id, revoked: false)
                let interlocutorLanguageSignal = wrapped_detectInterlocutorLanguage(forChatWith: peer.id, context: context)
                let recommendedChannels = context.engine.peers.recommendedChannels(peerId: peer.id)
                
                _ = (combineLatest(avatarImageSignal, inviteLinksSignal, interlocutorLanguageSignal, recommendedChannels)
                     |> take(1)).start(next: { avatarImageData, inviteLinks, interlocutorLanguage, recommendedChannels in
                    let peerData = PeerData(
                        avatarImageData: avatarImageData?.base64EncodedString(),
                        id: peerId,
                        inviteLinks: extractInviteLinks(inviteLinks),
                        payload: extractPayload(
                            peer: peer,
                            cachedData: cachedData,
                            interlocutorLanguage: interlocutorLanguage,
                            similarChannels: extractSimilarChannels(from: recommendedChannels)
                        ),
                        type: type
                    )
                    continuation.resume(returning: peerData)
                })
            }
        }
    )
}

private func extractPayload(
    peer: Peer,
    cachedData: CachedPeerData?,
    interlocutorLanguage: String?,
    similarChannels: [SimilarChannel]
) -> PeerPayload? {
    switch EnginePeer(peer) {
    case let .legacyGroup(group):
        PeerPayload.legacyGroup(
            extractPayload(
                group: group,
                cachedData: cachedData as? CachedGroupData,
                lastMessageLanguageCode: interlocutorLanguage
            )
        )
    case let .channel(channel):
        PeerPayload.channel(
            extractPayload(
                channel: channel,
                cachedData: cachedData as? CachedChannelData,
                lastMessageLanguageCode: interlocutorLanguage
            ),
            similarChannels
        )
    case let .user(user):
        if let botInfo = user.botInfo {
            PeerPayload.user(
                extractPayload(
                    bot: user,
                    botInfo: botInfo,
                    cachedData: cachedData as? CachedUserData,
                    lastMessageLanguageCode: interlocutorLanguage
                )
            )
        } else {
            nil
        }
    default:
        nil
    }
}

private func extractPayload(
    group: TelegramGroup,
    cachedData: CachedGroupData?,
    lastMessageLanguageCode: String?
) -> LegacyGroupPayload {
    LegacyGroupPayload(
        deactivated: group.flags.contains(.deactivated),
        title: group.title,
        participantsCount: group.participantCount,
        date: group.creationDate,
        migratedTo: group.migrationReference?.peerId.id._internalGetInt64Value(),
        photo: extractChatPhoto(peer: group),
        lastMessageLang: lastMessageLanguageCode,
        about: cachedData?.about
    )
}

private func extractPayload(
    channel: TelegramChannel,
    cachedData: CachedChannelData?,
    lastMessageLanguageCode: String?
) -> ChannelPayload {
    ChannelPayload(
        verified: channel.isVerified,
        scam: channel.isScam,
        hasGeo: channel.flags.contains(.hasGeo),
        fake: channel.isFake,
        gigagroup: channel.flags.contains(.isGigagroup),
        title: channel.title,
        username: channel.username,
        date: channel.creationDate,
        restrictions: extractRestrictions(restrictionInfo: channel.restrictionInfo),
        participantsCount: cachedData?.participantsSummary.memberCount,
        photo: extractChatPhoto(peer: channel),
        lastMessageLang: lastMessageLanguageCode,
        about: cachedData?.about,
        geoLocation: cachedData?.peerGeoLocation.map {
            extractGeoLocation($0)
        }
    )
}

private func extractPayload(
    bot: TelegramUser,
    botInfo: BotUserInfo,
    cachedData: CachedUserData?,
    lastMessageLanguageCode: String?
) -> UserPayload {
    let botFlags = botInfo.flags
    let userFlags = bot.flags
    
    return UserPayload(
        deleted: bot.isDeleted,
        bot: true,
        botChatHistory: botFlags.contains(.hasAccessToChatHistory),
        botNochats: !botFlags.contains(.worksWithGroups),
        verified: bot.isVerified,
        restricted: bot.restrictionInfo != nil,
        botInlineGeo: botFlags.contains(.requiresGeolocationForInlineRequests),
        support: userFlags.contains(.isSupport),
        scam: bot.isScam,
        fake: bot.isFake,
        botAttachMenu: botFlags.contains(.canBeAddedToAttachMenu),
        premium: bot.isPremium,
        botCanEdit: botFlags.contains(.canEdit),
        firstName: bot.firstName,
        lastName: bot.lastName,
        username: bot.username,
        phone: bot.phone,
        photo: extractUserProfilePhoto(peer: bot),
        restrictionReason: extractRestrictions(restrictionInfo: bot.restrictionInfo),
        botInlinePlaceholder: botInfo.inlinePlaceholder,
        langCode: lastMessageLanguageCode,
        usernames: bot.usernames.map {
            .init(
                editable: $0.flags.contains(.isEditable),
                active: $0.isActive,
                username: $0.username
            )
        },
        description: cachedData?.botInfo?.description
    )
}

private func extractChatPhoto(
    peer: Peer
) -> ChatPhoto? {
    guard let imageRepresentation = peer.profileImageRepresentations.first else {
        return nil
    }
    guard let resource = imageRepresentation.resource as? CloudPeerPhotoSizeMediaResource else {
        return nil
    }
    
    return ChatPhoto(mediaResourceId: resource.id.stringRepresentation, datacenterId: resource.datacenterId, photoId: resource.photoId, volumeId: resource.volumeId, localId: resource.localId, sizeSpec: resource.sizeSpec.rawValue)
}

private func extractUserProfilePhoto(
    peer: Peer
) -> UserProfilePhoto? {
    guard let imageRepresentation = peer.profileImageRepresentations.first else {
        return nil
    }
    guard let resource = imageRepresentation.resource as? CloudPeerPhotoSizeMediaResource else {
        return nil
    }
    
    return UserProfilePhoto(
        hasVideo: imageRepresentation.hasVideo,
        personal: imageRepresentation.isPersonal,
        photoId: resource.photoId,
        dcId: resource.datacenterId
    )
}

func extractParticipantsCount(peer: Peer, cachedData: CachedPeerData?) -> Int {
    switch EnginePeer(peer) {
    case .user:
        return 2
    case .channel:
        let channelData = cachedData as? CachedChannelData
        return Int(channelData?.participantsSummary.memberCount ?? 0)
    case let .legacyGroup(group):
        return group.participantCount
    case .secretChat:
        return 0
    }
}

private func extractRestrictions(
    restrictionInfo: PeerAccessRestrictionInfo?
) -> [FeatNicegramHub.RestrictionRule] {
    restrictionInfo?.rules.map {
        FeatNicegramHub.RestrictionRule(
            platform: $0.platform,
            reason: $0.reason,
            text: $0.text
        )
    } ?? []
}

private func extractGeoLocation(
    _ geo: PeerGeoLocation
) -> GeoLocation {
    GeoLocation(latitude: geo.latitude, longitude: geo.longitude, address: geo.address)
}

private func extractInviteLinks(
    _ links: ExportedInvitations?
) -> [InviteLink]? {
    links?.list?.compactMap { link in
        switch link {
        case let .link(link, title, isPermanent, requestApproval, isRevoked, adminId, date, startDate, expireDate, usageLimit, count, requestedCount, _):
            InviteLink(link: link, title: title, isPermanent: isPermanent, requestApproval: requestApproval, isRevoked: isRevoked, adminId: adminId.id._internalGetInt64Value(), date: date, startDate: startDate, expireDate: expireDate, usageLimit: usageLimit, count: count, requestedCount: requestedCount)
        case .publicJoinRequest:
            nil
        }
    }
}

private func extractSimilarChannels(
    from recommendedChannels: RecommendedChannels?
) -> [SimilarChannel] {
    guard let recommendedChannels else { return [] }
    
    return recommendedChannels.channels.compactMap { channel in
        switch channel.peer {
        case let .channel(telegramChannel):
            let channelPayload = extractPayload(
                channel: telegramChannel,
                cachedData: nil,
                lastMessageLanguageCode: nil
            )

            return SimilarChannel(
                id: telegramChannel.id.toInt64(),
                inviteLinks: nil,
                payload: .channel(channelPayload, []),
                type: .channel,
                icon: extractIcon(from: channel.peer, accessHash: telegramChannel.accessHash?.value)
            )
        default: return nil
        }
    }
}

private func extractIcon(
    from peer: EnginePeer,
    accessHash: Int64?
) -> SimilarChannel.Icon? {
    guard let imageRepresentation = peer._asPeer().profileImageRepresentations.first else {
        return nil
    }
    guard let resource = imageRepresentation.resource as? CloudPeerPhotoSizeMediaResource else {
        return nil
    }
    
    return .init(
        id: resource.photoId ?? 0,
        accessHash: accessHash,
        datacenterId: Int32(resource.datacenterId)
    )
}
