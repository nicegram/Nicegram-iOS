import Foundation
import MemberwiseInit
import NGUtils
import TelegramBridge

@MemberwiseInit
class TelegramMediaFetcherImpl {
    @Init(.internal) private let contextProvider: ContextProvider
}

extension TelegramMediaFetcherImpl: TelegramMediaFetcher {
    func get(
        id: TelegramMediaId,
        options: Options
    ) async throws -> URL {
        let context = try contextProvider.context().unwrap()
        
        return try await MediaFetcher(context: context)
            .getMedia(
                id: .init(id),
                options: .init(
                    fetchIfMissing: options.fetchIfMissing,
                    fetchTimeout: options.fetchTimeout
                )
            )
    }
    
    func getDirectlyFromApi(
        location: TelegramMediaApiLocation
    ) async throws -> URL {
        let context = try contextProvider.context().unwrap()
        
        return try await ApiMediaFetcher(context: context)
            .fetch(location: location)
    }
}
