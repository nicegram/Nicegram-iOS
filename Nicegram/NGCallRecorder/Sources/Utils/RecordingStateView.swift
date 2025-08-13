import CoreSwiftUI
import NGCoreUI
import NGStrings
import SwiftUI

public class RecordingStateView: UIView {
    public struct Constants {
        public static let height = 28.0
    }
    
    public let callRecorder: CallRecorder
    
    public init(callRecorder: CallRecorder) {
        self.callRecorder = callRecorder
        
        super.init(frame: .zero)
        
        self.alpha = 0
        
        if #available(iOS 16.0, *) {
            let contentView = UIHostingConfiguration {
                ContentView(callRecorder: callRecorder)
            }.margins(.all, 0).makeContentView()
            self.addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 15.0, *)
private struct ContentView: View {
    @ObservedObject var callRecorder: CallRecorder
    var isRecording: Bool {
        callRecorder.state.is(\.recording)
    }
    
    var body: some View {
        badgeView(
            backgroundColor: isRecording ? .red : .white.opacity(0.3),
            image: Image(
                isRecording ? NGCoreUI.images.recordStop : NGCoreUI.images.recordStart
            ),
            text: {
                if let startDate = callRecorder.state.recording?.startDate {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(
                            recordingText(
                                startDate: startDate,
                                currentDate: context.date
                            )
                        )
                    }
                } else {
                    Text(l("NicegramCallRecord.Record"))
                }
            },
            onClick: callRecorder.onToggleClick
        )
        .frame(maxWidth: .infinity)
        .animation(.default, value: callRecorder.state)
    }
}

@available(iOS 15.0, *)
private extension ContentView {
    func badgeView(
        backgroundColor: Color,
        image: Image,
        @ViewBuilder text: () -> some View,
        onClick: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 4) {
            image
                .fixedSize(20)
            text()
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                ._wrapperKerning(0.14)
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .frame(maxHeight: .infinity)
        .wrapInButton(action: onClick)
        .background(backgroundColor)
        .clipShape(.capsule)
    }
}

@available(iOS 15.0, *)
private extension ContentView {
    func recordingText(
        startDate: Date,
        currentDate: Date
    ) -> String {
        var result = l("NicegramCallRecord.Stop")
        result += " "
        result += formattedDuration(startDate: startDate, currentDate: currentDate)
        return result
    }
    
    func formattedDuration(
        startDate: Date,
        currentDate: Date
    ) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: startDate, to: currentDate) ?? ""
    }
}
