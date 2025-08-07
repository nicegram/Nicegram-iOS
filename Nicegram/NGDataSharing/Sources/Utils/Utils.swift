import FeatDataSharing
import NaturalLanguage

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

    let getConfigUseCase = DataSharingModule.shared.getConfigUseCase()
    let config = getConfigUseCase()
    
    let messages = messages
        .filter {
            !$0.message.isEmpty || ($0.media != nil)
        }
        .sorted { $0.date > $1.date }
    
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
        .prefix(config.messagesLimit)
        .map(\.messages)
        .reduce([], +)
    return result
}
