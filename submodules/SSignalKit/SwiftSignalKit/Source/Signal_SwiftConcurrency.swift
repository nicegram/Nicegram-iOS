import Foundation

// MARK: Signal to SwiftConcurrency

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

public extension Signal {
    func awaitForCompletion() async throws {
        let stream = self.asyncStream(.unbounded)
        for try await value in stream {}
    }
}

public struct ErrorAdapter<E>: Error, LocalizedError {
    let error: E
    
    public var errorDescription: String? {
        "\(error)"
    }
}

// MARK: SwiftConcurrency to Signal

public extension Signal {
    static func awaitOperation(
        operation: @escaping () async -> T
    ) -> Signal<T, NoError> where E == NoError {
        Signal<T, Error>.awaitThrowingOperation(operation: operation)
        |> `catch` { _ in .complete() }
    }
    
    static func awaitThrowingOperation(
        operation: @escaping () async throws -> T
    ) -> Self where E == Error {
        Self { subscriber in
            let task = Task {
                do {
                    let result = try await operation()
                    subscriber.putNext(result)
                    subscriber.putCompletion()
                } catch {
                    subscriber.putError(error)
                }
            }
            
            return ActionDisposable {
                task.cancel()
            }
        }
    }
}
