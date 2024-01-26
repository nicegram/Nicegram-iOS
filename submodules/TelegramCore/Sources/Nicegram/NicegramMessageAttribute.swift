import Postbox

public class NicegramMessageAttribute: MessageAttribute {
    public var isDeleted: Bool
    public var originalText: String?
    
    public init(
        isDeleted: Bool = false,
        originalText: String? = nil
    ) {
        self.isDeleted = isDeleted
        self.originalText = originalText
    }
    
    public required init(decoder: PostboxDecoder) {
        self.isDeleted = decoder.decodeBoolForKey("isDeleted", orElse: false)
        self.originalText = decoder.decodeOptionalStringForKey("originalText")
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeBool(isDeleted, forKey: "isDeleted")
        if let originalText {
            encoder.encodeString(originalText, forKey: "originalText")
        }
    }
}

public extension Message {
    var nicegramAttribute: NicegramMessageAttribute {
        for attribute in self.attributes {
            if let nicegramAttribute = attribute as? NicegramMessageAttribute {
                return nicegramAttribute
            }
        }
        return NicegramMessageAttribute()
    }
}

public extension Transaction {
    func updateNicegramAttribute(messageId: MessageId, _ block: (inout NicegramMessageAttribute) -> Void) {
        self.updateMessage(messageId) { message in
            var attributes = message.attributes
            attributes.updateNicegramAttribute(block)
            
            return .update(StoreMessage(id: message.id, globallyUniqueId: message.globallyUniqueId, groupingKey: message.groupingKey, threadId: message.threadId, timestamp: message.timestamp, flags: StoreMessageFlags(message.flags), tags: message.tags, globalTags: message.globalTags, localTags: message.localTags, forwardInfo: message.forwardInfo.map(StoreMessageForwardInfo.init), authorId: message.author?.id, text: message.text, attributes: attributes, media: message.media))
        }
    }
}

public extension StoreMessage {
    func updatingNicegramAttributeOnEdit(
        previousMessage: Message
    ) -> StoreMessage {
        let newAttr = self.attributes.compactMap { $0 as? NicegramMessageAttribute }.first
        let attr = newAttr ?? previousMessage.nicegramAttribute
        
        if attr.originalText == nil {
            attr.originalText = previousMessage.text
        }
        
        var attributes = self.attributes
        attributes.updateNicegramAttribute {
            $0 = attr
        }
        
        return self.withUpdatedAttributes(attributes)
    }
}

private extension Array<MessageAttribute> {
    mutating func updateNicegramAttribute(
        _ block: (inout NicegramMessageAttribute) -> Void
    ) {
        for (index, attribute) in self.enumerated() {
            if var nicegramAttribute = attribute as? NicegramMessageAttribute {
                block(&nicegramAttribute)
                self[index] = nicegramAttribute
                return
            }
        }
        
        var nicegramAttribute = NicegramMessageAttribute()
        block(&nicegramAttribute)
        self.append(nicegramAttribute)
    }
}
