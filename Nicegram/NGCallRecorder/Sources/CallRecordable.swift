import AccountContext
import MemberwiseInit
import Postbox
import SwiftSignalKit
import TelegramVoip

@MemberwiseInit(.public)
public class CallRecordable {
    public let accountContext: AccountContext
    public weak var audioDevice: OngoingCallContext.AudioDevice?
    public let peerId: PeerId?
    public let callActive: Signal<Bool, NoError>
    public let callTitle: () async -> String
}
