import FeatCalls
import TelegramCallsUI
import TelegramAudio
import Combine

final class NicegramCallsAudioContextImpl {
    private let sharedContext: SharedCallAudioContext
    
    init(sharedContext: SharedCallAudioContext) {
        self.sharedContext = sharedContext
    }
}

extension NicegramCallsAudioContextImpl: NicegramCallsAudioContext {
    var routeStatePublisher: AnyPublisher<NGAudioRouteState, Never> {
        sharedContext.audioOutputState
            .skipError()
            .toPublisher()
            .compactMap({ state in
                guard let currentOutput = state.1 else {
                    return nil
                }
                
                let outputs = state.0
                
                return NGAudioRouteState(
                    availableOutputs: outputs.map { NGAudioSessionOutput($0) },
                    currentOutput: .init(currentOutput)
                )
            })
            .eraseToAnyPublisher()
    }
    
    func selectAudioOutput(_ output: NGAudioSessionOutput) {
        sharedContext.setCurrentAudioOutput(output.toOriginal())
    }
}
