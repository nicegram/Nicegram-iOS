import FeatDataSharing
import NaturalLanguage

struct DataSharingConstants {
    static let fetchMessagesCount = 100
    static let shareMessagesCount = 10
}

func getLanguageCode(messages: [Message]) -> String? {
    let messages = messages
        .sorted { $0.date > $1.date }
        .compactMap { $0.message }
    
    let message = messages.first { $0.count >= 16 } ?? messages.first { !$0.isEmpty }
    guard let message else { return nil }
    
    return NLLanguageRecognizer.dominantLanguage(for: message)?.rawValue
}

func prepareForSharing(messages: [Message]) -> [Message] {
    struct GroupedMessages {
        let groupedId: Int64?
        var messages: [Message]
    }
    
    let messages = messages.sorted { $0.date > $1.date }
    
    var groupedMessages: [GroupedMessages] = []
    for message in messages {
        if let groupedId = message.groupedId,
           let hitIndex = groupedMessages.firstIndex(where: { $0.groupedId == groupedId }) {
            groupedMessages[hitIndex].messages.append(message)
        } else {
            groupedMessages.append(
                GroupedMessages(
                    groupedId: message.groupedId,
                    messages: [message]
                )
            )
        }
    }
    
    let result = groupedMessages
        .prefix(DataSharingConstants.shareMessagesCount)
        .map(\.messages)
        .reduce([], +)
    return result
}
