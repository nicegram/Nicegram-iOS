import Foundation

final class MutableTypingDraftsView: MutablePostboxView {
    fileprivate let peerAndThreadId: PeerAndThreadId
    fileprivate var typingDraft: Message?
    
    init(postbox: PostboxImpl, peerAndThreadId: PeerAndThreadId) {
        self.peerAndThreadId = peerAndThreadId
        
        self.reload(postbox: postbox)
    }
    
    private func reload(postbox: PostboxImpl) {
        if let typingDraft = postbox.currentTypingDrafts[self.peerAndThreadId] {
            self.typingDraft = self.renderTypingDraft(postbox: postbox, typingDraft: typingDraft)
        } else {
            self.typingDraft = nil
        }
    }
    
    func replay(postbox: PostboxImpl, transaction: PostboxTransaction) -> Bool {
        var updated = false
        
        if let typingDraftUpdate = transaction.updatedTypingDrafts[self.peerAndThreadId] {
            if let typingDraft = typingDraftUpdate.value {
                self.typingDraft = self.renderTypingDraft(postbox: postbox, typingDraft: typingDraft)
            } else {
                self.typingDraft = nil
            }
            updated = true
        }
        
        return updated
    }

    private func renderTypingDraft(postbox: PostboxImpl, typingDraft: PostboxImpl.TypingDraft) -> Message? {
        guard let peer = postbox.peerTable.get(self.peerAndThreadId.peerId), let author = postbox.peerTable.get(typingDraft.authorId) else {
            return nil
        }
        
        var peers = SimpleDictionary<PeerId, Peer>()
        peers[peer.id] = peer
        peers[author.id] = author
        
        var associatedThreadInfo: Message.AssociatedThreadInfo?
        if let threadId = typingDraft.threadId, let data = postbox.messageHistoryThreadIndexTable.get(peerId: self.peerAndThreadId.peerId, threadId: threadId) {
            associatedThreadInfo = postbox.seedConfiguration.decodeMessageThreadInfo(data.data)
        }
        
        return Message(
            stableId: typingDraft.stableId,
            stableVersion: typingDraft.stableVersion,
            id: MessageId(
                peerId: self.peerAndThreadId.peerId,
                namespace: 1,
                id: Int32.max - 50000),
            globallyUniqueId: nil,
            groupingKey: nil,
            groupInfo: nil,
            threadId: typingDraft.threadId,
            timestamp: typingDraft.timestamp,
            flags: [.Incoming],
            tags: [],
            globalTags: [],
            localTags: [],
            customTags: [],
            forwardInfo: nil,
            author: author,
            text: typingDraft.text,
            attributes: typingDraft.attributes,
            media: [],
            peers: peers,
            associatedMessages: SimpleDictionary(),
            associatedMessageIds: [],
            associatedMedia: [:],
            associatedThreadInfo: associatedThreadInfo,
            associatedStories: [:]
        )
    }

    func refreshDueToExternalTransaction(postbox: PostboxImpl) -> Bool {
        self.reload(postbox: postbox)
        
        return true
    }
    
    func immutableView() -> PostboxView {
        return TypingDraftsView(self)
    }
}

public final class TypingDraftsView: PostboxView {
    public let typingDraft: Message?
    
    init(_ view: MutableTypingDraftsView) {
        self.typingDraft = view.typingDraft
    }
}
