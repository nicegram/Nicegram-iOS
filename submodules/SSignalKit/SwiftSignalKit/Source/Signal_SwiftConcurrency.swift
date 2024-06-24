// MARK: Nicegram

public class SignalAsyncStream<T, E>: AsyncSequence {
    public typealias Element = T
    public typealias AsyncIterator = SignalAsyncStream<T, E>
    
    public func makeAsyncIterator() -> Self {
        return self
    }
    
    private let stream: AsyncStream<T>
    
    private lazy var iterator = stream.makeAsyncIterator()
    
    public init(
        _ upstream: Signal<T, E>,
        bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy
    ) {
        stream = AsyncStream(T.self, bufferingPolicy: bufferingPolicy) { continuation in
            let disposable = upstream.start(
                next: { value in
                    continuation.yield(value)
                },
                error: { _ in
                    continuation.finish()
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
    public func next() async -> T? {
        return await iterator.next()
    }
}

public extension Signal {
    func asyncStream(
        _ bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy
    ) -> SignalAsyncStream<T, E> {
        SignalAsyncStream(self, bufferingPolicy: bufferingPolicy)
    }
}


public extension Signal {
    func awaitForFirstValue() async throws -> T {
        let stream = self.asyncStream(.unbounded)
        for await value in stream {
            return value
        }
        throw CancellationError()
    }
}

