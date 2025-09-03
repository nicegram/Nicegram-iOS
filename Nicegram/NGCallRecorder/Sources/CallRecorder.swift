import CasePaths
import Combine
import Foundation
import NGCore
import NGData

@preconcurrency @MainActor
public class CallRecorder: ObservableObject {
    @CasePathable @dynamicMemberLookup
    public enum State: Equatable {
        case recording(Recording)
        case notRecording
        
        public struct Recording: Equatable {
            public let startDate: Date
        }
    }
    
    //  MARK: - Public Properties
    
    @Published public var state: State = .notRecording
    
    //  MARK: - Internal Properties
    
    var call: CallRecordable?
    
    let partLength: TimeInterval = 30 * .minute
    var partNumber = 1
    var partsTimer: AnyCancellable?
    
    let log = Log(category: "call-recorder")
    
    //  MARK: - Lifecycle
    
    public init() {}
}

//  MARK: - Public Functions

public extension CallRecorder {
    func updateCall(_ call: CallRecordable) {
        let isInitial = (self.call == nil)
        
        self.call = call
        
        if isInitial, NGSettings.recordAllCalls {
            Task {
                try await waitForCallActive()
                trackCallRecorderEvent(.startAuto)
                startRecordCall()
            }
        }
    }
    
    func onStartClick() {
        trackCallRecorderEvent(.start)
        startRecordCall()
    }
    
    func onStopClick() {
        showCallRecordingEndConfirmation()
    }
    
    func onToggleClick() {
        switch state {
        case .notRecording: onStartClick()
        case .recording: onStopClick()
        }
    }
}

//  MARK: - Internal Functions

extension CallRecorder {
    func startRecordCall() {
        self.state = .recording(
            .init(
                startDate: Date()
            )
        )
        
        self.partNumber = 1
        self.partsTimer = Timer
            .publish(every: partLength, tolerance: 0, on: .main, in: .common)
            .autoconnect()
            .prepend(Date())
            .sink { [weak self] _ in
                guard let self else { return }
                
                stopRecordAudioDevice()
                startRecordAudioDevice()
            }
    }
    
    func stopRecordCall() {
        self.partNumber = 1
        self.partsTimer = nil
        self.state = .notRecording
        
        stopRecordAudioDevice()
        
        trackCallRecorderEvent(.end)
    }
}

private extension CallRecorder {
    func startRecordAudioDevice() {
        guard let audioDevice = call?.audioDevice else {
            return
        }
        
        log("start recording audio device")
        audioDevice.startNicegramRecording(
            callback: { [self] path, duration, size in
                log("audio device success")
                processRecordedAudio(
                    RecordedAudio(
                        path: path,
                        duration: duration,
                        size: size
                    )
                )
            },
            errorCallback: { _ in
                self.log("audio device error")
                trackCallRecorderEvent(.error)
            }
        )
    }
    
    func stopRecordAudioDevice() {
        if let audioDevice = call?.audioDevice {
            log("stop recording audio device")
            audioDevice.stopNicegramRecording()
        }
    }
    
    func processRecordedAudio(_ audio: RecordedAudio) {
        let partNumber = self.partNumber
        self.partNumber += 1
        
        Task {
            try await sendAudioToSavedMessages(
                audio: audio,
                partNumber: partNumber
            )
            showRecordSavedToast()
            log("record saved")
        }
    }
    
    func waitForCallActive() async throws {
        _ = try await call.unwrap().callActive
            .toPublisher()
            .filter { $0 }
            .awaitForFirstValue()
    }
}
