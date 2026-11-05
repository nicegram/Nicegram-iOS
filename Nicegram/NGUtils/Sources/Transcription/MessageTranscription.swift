import AccountContext
import SwiftSignalKit
import TelegramCore

extension EngineRawMessage {
    func setTranscription(
        _ text: String,
        context: AccountContext
    ) async {
        let attribute = AudioTranscriptionMessageAttribute(
            id: 0,
            text: text,
            isPending: false,
            didRate: false,
            error: nil
        )

        try? await TelegramRawPostbox
            .updateMessage(
                id,
                engine: context.engine,
                update: { currentText, currentAttributes in
                    var attributes = currentAttributes.filter { !($0 is AudioTranscriptionMessageAttribute) }
                    attributes.append(attribute)
                    return (currentText, attributes)
                }
            )
            .awaitForCompletion()
    }
}
