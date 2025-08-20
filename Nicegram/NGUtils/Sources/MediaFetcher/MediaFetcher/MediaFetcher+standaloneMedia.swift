import Foundation
import NGCore
import Postbox
import TelegramCore

public extension MediaFetcher {
    func getMedia(
        id: MediaId,
        options: Options
    ) async throws -> URL {
        let media = try await getMedia(id)
        let resource = try getResource(media)
        
        return try await getResourceFile(
            mediaResourceReference: .media(
                media: .standalone(media: media),
                resource: resource
            ),
            userLocation: .other,
            userContentType: .other,
            options: options
        )
    }
}

private extension MediaFetcher {
    func getMedia(_ id: MediaId) async throws -> Media {
        try await context.account.postbox.transaction { transaction in
            transaction.getMedia(id)
        }.awaitForFirstValue().unwrap()
    }

    func getResource(_ media: Media) throws -> MediaResource {
        switch media {
        case let image as TelegramMediaImage:
            let largestImageRepresentation = try largestImageRepresentation(image.representations).unwrap()
            return largestImageRepresentation.resource
        case let file as TelegramMediaFile:
            return file.resource
        default:
            throw UnexpectedError()
        }
    }
}
