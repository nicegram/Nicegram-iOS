import Foundation

// MARK: Nicegram

public class SignalAsyncStream<T, E: Error>: AsyncSequence {
    public typealias Element = T
    public typealias AsyncIterator = SignalAsyncStream<T, E>
    
    public func makeAsyncIterator() -> Self {
        return self
    }
    
    private let stream: AsyncThrowingStream<T, Error>
    private lazy var iterator = stream.makeAsyncIterator()
    
    public init(
        _ upstream: Signal<T, E>,
        bufferingPolicy: AsyncThrowingStream<T, Error>.Continuation.BufferingPolicy
    ) {
        stream = AsyncThrowingStream(bufferingPolicy: bufferingPolicy) { continuation in
            let disposable = upstream.start(
                next: { value in
                    continuation.yield(value)
                },
                error: { error in
                    continuation.finish(throwing: error)
                },
                completed: {
                    continuation.finish()
                }
            )
            
            continuation.onTermination = { _ in
                disposable.dispose()
            }
        }
    }
}

extension SignalAsyncStream: AsyncIteratorProtocol {
    public func next() async throws -> T? {
        return try await iterator.next()
    }
}

public extension Signal {
    func asyncStream(
        _ bufferingPolicy: AsyncThrowingStream<T, Error>.Continuation.BufferingPolicy
    ) -> SignalAsyncStream<T, E> where E: Error {
        SignalAsyncStream(self, bufferingPolicy: bufferingPolicy)
    }
    
    func asyncStream(
        _ bufferingPolicy: AsyncThrowingStream<T, Error>.Continuation.BufferingPolicy
    ) -> SignalAsyncStream<T, ErrorAdapter<E>> {
        let signal = self |> mapError { error in
            ErrorAdapter(error: error)
        }
        return SignalAsyncStream(signal, bufferingPolicy: bufferingPolicy)
    }
}

public extension Signal {
    func awaitForFirstValue() async throws -> T where E: Error {
        let stream = self.asyncStream(.unbounded)
        for try await value in stream {
            return value
        }
        throw CancellationError()
    }
    
    func awaitForFirstValue() async throws -> T {
        let stream = self.asyncStream(.unbounded)
        for try await value in stream {
            return value
        }
        throw CancellationError()
    }
}

public struct ErrorAdapter<E>: Error, LocalizedError {
    let error: E
    
    public var errorDescription: String? {
        "\(error)"
    }
}
