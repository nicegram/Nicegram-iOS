import protocol Postbox.Media
import TelegramBridge
import TelegramCore

private struct TelegramMediaImpl: TelegramBridge.TelegramMedia {
    let type: TelegramMediaType
}

public extension Postbox.Media {
    func toTelegramBridgeMedia() -> TelegramBridge.TelegramMedia {
        let type: TelegramMediaType
        switch self {
        case let file as TelegramMediaFile:
            type = file.isVideo ? .video : .file
        case _ as TelegramMediaImage:
            type = .image
        default:
            type = .other
        }
        
        return TelegramMediaImpl(
            type: type
        )
    }
}

public extension [Postbox.Media] {
    func toTelegramBridgeMedia() -> [TelegramBridge.TelegramMedia] {
        self.map { $0.toTelegramBridgeMedia() }
    }
}
