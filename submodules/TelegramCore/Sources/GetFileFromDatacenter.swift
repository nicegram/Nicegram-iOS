import Foundation
import SwiftSignalKit
import TelegramApi
import MtProtoKit
import Postbox

public func getFile(
    with network: Network,
    peer: Api.InputPeer,
    flags: Int32,
    photoId: Int64,
    datacenterId: Int32
) -> Signal<Api.upload.File, MTRpcError> {
    network.download(datacenterId: Int(datacenterId), isMedia: false, tag: nil)    
    |> castError(MTRpcError.self)
    |> mapToSignal { worker in
        worker.request(Api.functions.upload.getFile(
            flags: flags,
            location: .inputPeerPhotoFileLocation(
                flags: flags,
                peer: peer,
                photoId: photoId
            ),
            offset: 0,
            limit: 512*1024
        ))
    }
}

public func peer(with chat: Api.Chat?) -> Peer? {
    guard let chat else { return nil }
    
    return parseTelegramGroupOrChannel(chat: chat)
}
