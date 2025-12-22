import AccountContext
import NGCallRecorder
import SwiftSignalKit
import TelegramCore

public extension CallRecordable {
    convenience init(_ call: PresentationGroupCallImpl) {
        let context = call.accountContext
        let peerId = call.peerId
        let summaryState = call.summaryState
        
        self.init(
            accountContext: context,
            audioDevice: call.sharedAudioContext?.audioDevice,
            peerId: peerId,
            callActive: call.state
            |> map { state in
                if case .connected = state.networkState {
                    true
                } else {
                    false
                }
            },
            callTitle: {
                let title = try? await CallTitleProvider(
                    context: context,
                    peerId: peerId,
                    summaryState: summaryState.awaitForFirstValue()
                ).get()
                
                var result = "Group Call"
                if let title, !title.isEmpty {
                    result += "-\(title)"
                }
                return result
            }
        )
    }
}

private struct CallTitleProvider {
    let context: AccountContext
    let peerId: EnginePeer.Id?
    let summaryState: PresentationGroupCallSummaryState?
    
    func get() async -> String? {
        if let title = getCustomTitle() {
            return title
        }
        if let title = await getPeerTitle() {
            return title
        }
        return getMembersTitle()
    }
    
    private func getCustomTitle() -> String? {
        summaryState?.info?.title
    }
    
    private func getPeerTitle() async -> String? {
        try? await context.engine.data.get(
            TelegramEngine.EngineData.Item.Peer.Peer(id: peerId.unwrap())
        ).awaitForFirstValue()?.debugDisplayTitle
    }
    
    private func getMembersTitle() -> String? {
        do {
            let summaryState = try summaryState.unwrap()
            
            let members = summaryState.topParticipants
                .compactMap(\.peer?.debugDisplayTitle)
                .prefix(4)
            let membersString = members.joined(separator: ", ")
            
            let otherCount = summaryState.participantCount - members.count
            
            if otherCount == 0 {
                return membersString
            } else if otherCount == 1 {
                return "\(membersString) and 1 other"
            } else {
                return "\(membersString) and \(otherCount) others"
            }
        } catch {
            return nil
        }
    }
}
