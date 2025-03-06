import Combine

// MARK: Signal to Publisher

public extension Signal {
    func toPublisher() -> SignalPublisher<T, E> where E: Error {
        SignalPublisher(signal: self)
    }
    
    func toPublisher() -> SignalPublisher<T, Never> where E == NoError {
        SignalPublisher(signal: self |> castError(Never.self))
    }
}

public struct SignalPublisher<Output, Failure: Error>: Combine.Publisher {
    private let signal: Signal<Output, Failure>
    
    public init(signal: Signal<Output, Failure>) {
        self.signal = signal
    }
    
    public func receive<S: Combine.Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = SignalPublisherSubscription(
            signal: signal,
            subscriber: subscriber
        )
        subscriber.receive(subscription: subscription)
    }
}

private class SignalPublisherSubscription<S: Combine.Subscriber>: Combine.Subscription {
    private var disposable: Disposable?
    
    init<Output, Failure>(signal: Signal<Output, Failure>, subscriber: S) where S.Input == Output, S.Failure == Failure {
        self.disposable = signal.start(
            next: {
                _ = subscriber.receive($0)
            },
            error: {
                subscriber.receive(completion: .failure($0))
            },
            completed: {
                subscriber.receive(completion: .finished)
            }
        )
    }
    
    func request(_ demand: Combine.Subscribers.Demand) {}
    
    func cancel() {
        disposable?.dispose()
        disposable = nil
    }
}

// MARK: Publisher to Signal

@available(iOS 13.0, *)
public extension Publisher {
    func toSignal() -> Signal<Output, Failure> {
        Signal { subscriber in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let failure):
                        subscriber.putError(failure)
                    }
                    
                    subscriber.putCompletion()
                },
                receiveValue: { value in
                    subscriber.putNext(value)
                }
            )
            
            return ActionDisposable {
                cancellable.cancel()
            }
        }
    }
}

public extension Signal {
    func skipError() -> Signal<T, NoError> {
        Signal<T, NoError> { subscriber in
            self.start(
                next: {
                    subscriber.putNext($0)
                },
                completed: {
                    subscriber.putCompletion()
                }
            )
        }
    }
}
