import Combine

// MARK: Nicegram

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

public extension Signal {
    func toAnyPublisher() -> AnyPublisher<T, Never> {
        let subject = PassthroughSubject<T, Never>()
        
        let disposable = self.start(next: { value in
            subject.send(value)
        }, completed: {
            subject.send(completion: .finished)
        })
        
        return subject
            .handleEvents(receiveCancel: {
                disposable.dispose()
            })
            .eraseToAnyPublisher()
    }
}
