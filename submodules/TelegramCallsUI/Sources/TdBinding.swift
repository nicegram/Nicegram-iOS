import Foundation

class TdKeyPair: NSObject {
    let keyId: Int64
    let publicKey: Data
    
    init?(keyId: Int64, publicKey: Data) {
        self.keyId = keyId
        self.publicKey = publicKey
    }
    
    static func generate() -> TdKeyPair? {
        TdKeyPair(keyId: 0, publicKey: Data())
    }
}

class TdCallParticipant: NSObject {
    let internalId: String
    let userId: Int64
    
    init(internalId: String, userId: Int64) {
        self.internalId = internalId
        self.userId = userId
    }
}

class TdCall: NSObject {
    static func make(with keyPair: TdKeyPair, userId: Int64, latestBlock: Data) -> TdCall? {
        nil
    }
    
    func takeOutgoingBroadcastBlocks() -> [Data] {
        []
    }
    
    func emojiState() -> Data? {
        nil
    }
    
    func participants() -> [TdCallParticipant] {
        []
    }
    
    func applyBlock(_ block: Data) {
        
    }
    
    func applyBroadcastBlock(_ block: Data) {
        
    }
    
    func generateRemoveParticipantsBlock(_ participantIds: [NSNumber]) -> Data? {
        nil
    }
    
    func encrypt(_ message: Data, channelId: Int32, plaintextPrefixLength: Int) -> Data? {
        nil
    }

    func decrypt(_ message: Data, userId: Int64) -> Data? {
        nil
    }
}

func tdGenerateZeroBlock(_ keyPair: TdKeyPair, _ userId: Int64) -> Data? {
    nil
}

func tdGenerateSelfAddBlock(_ keyPair: TdKeyPair, _ userId: Int64, _ previousBlock: Data) -> Data? {
    nil
}
