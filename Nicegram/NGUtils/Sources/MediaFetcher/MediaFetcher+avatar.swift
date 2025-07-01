import Foundation
import Postbox
import TelegramCore

public extension MediaFetcher {
    func getAvatarImage(
        peer: Peer,
        options: Options
    ) async throws -> Data {
        let peerReference = try PeerReference(peer).unwrap()
        
        let photo = peer.profileImageRepresentations
        let imageRepresentationWithMaxDimension = photo.max(by: { $0.dimensions.width < $1.dimensions.width })
        let imageRepresentation = try imageRepresentationWithMaxDimension.unwrap()
        
        let url = try await getResourceFile(
            mediaResourceReference: .avatar(
                peer: peerReference,
                resource: imageRepresentation.resource
            ),
            userLocation: .other,
            userContentType: .avatar,
            options: options
        )
        return try Data(contentsOf: url)
    }
}
