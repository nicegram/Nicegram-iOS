import MtProtoKit
import NGCore
import SwiftSignalKit
import TelegramCore

struct ChannelCollectorRpcError: Error {
    let code: Int32
    let name: String
}

/// A FLOOD_WAIT reaches the collector as an error instead of being waited out, and a request
/// that does not answer within 30 seconds (MTProto retries forever offline) fails with `TimeoutError`.
func sendChannelCollectorRequest<Result>(
    _ function: TelegramRawApi.Function<Result>,
    network: Network
) async throws -> Result {
    // Mapped before awaiting: awaiting a raw MTRpcError wraps it in an ErrorAdapter that hides it.
    try await (
        TelegramRawApi.request(
            function,
            network: network,
            automaticFloodWait: false
        )
        |> mapError { error -> Error in
            ChannelCollectorRpcError(
                code: error.errorCode,
                name: error.errorDescription
            )
        }
        |> timeout(
            30,
            queue: .concurrentDefaultQueue(),
            alternate: .fail(TimeoutError())
        )
    ).awaitForFirstValue()
}
