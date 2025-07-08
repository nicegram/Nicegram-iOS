import AccountContext
import Foundation
import MemberwiseInit
import NGCore
import Postbox
import SwiftSignalKit
import TelegramCore

public class MediaFetcher {
    @MemberwiseInit(.public)
    public struct Options {
        public let fetchIfMissing: Bool
        public let fetchTimeout: Double
    }
    
    let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
    }
}

public extension MediaFetcher {
    func getResourceFile(
        mediaResourceReference: MediaResourceReference,
        userLocation: MediaResourceUserLocation,
        userContentType: MediaResourceUserContentType,
        options: Options
    ) async throws -> URL {
        let cachedResource = await getCachedResource(
            mediaResourceReference: mediaResourceReference
        )
        if let cachedResource {
            return cachedResource
        }
        
        if options.fetchIfMissing {
            return try await fetchResource(
                mediaResourceReference: mediaResourceReference,
                userLocation: userLocation,
                userContentType: userContentType,
                options: options
            )
        } else {
            throw UnexpectedError()
        }
    }
}

private extension MediaFetcher {
    func getCachedResource(
        mediaResourceReference: MediaResourceReference
    ) async -> URL? {
        do {
            let data = try await context.account.postbox.mediaBox
                .resourceData(mediaResourceReference.resource)
                .awaitForFirstValue()
            
            if data.complete {
                return URL(fileURLWithPath: data.path)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    func fetchResource(
        mediaResourceReference: MediaResourceReference,
        userLocation: MediaResourceUserLocation,
        userContentType: MediaResourceUserContentType,
        options: Options
    ) async throws -> URL {
        let fetchSignal = fetchedMediaResource(
            mediaBox: context.account.postbox.mediaBox,
            userLocation: userLocation,
            userContentType: userContentType,
            reference: mediaResourceReference
        )
        |> timeout(
            options.fetchTimeout,
            queue: Queue.concurrentDefaultQueue(),
            alternate: .fail(.generic)
        )
        try await fetchSignal.awaitForCompletion()
        
        return try await getCachedResource(
            mediaResourceReference: mediaResourceReference
        ).unwrap()
    }
}
