import Combine
import UIKit

public class RecordIndicatorView: UIView {
    
    //  MARK: - UI Elements
    
    private let imageView = UIImageView()
    private let label = UILabel()
    
    //  MARK: - Logic
    
    private var state: CallRecorder.State = .notRecording
    private var timer: AnyCancellable?
    
    //  MARK: - Lifecycle
    
    public init() {
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.backgroundColor = UIColor(hexString: "FF453A")
        
        imageView.image = UIImage(bundleImageName: "RecordIndicator")
        
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .regular)
        label.textColor = .white
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.top.greaterThanOrEqualToSuperview()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.frame.height / 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //  MARK: - Public Functions
    
    public func set(state: CallRecorder.State) {
        guard self.state != state else {
            return
        }
        
        self.state = state
        
        if let startDate = state.recording?.startDate {
            self.timer = Timer
                .publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .prepend(Date())
                .sink { [weak self] date in
                    guard let self else { return }
                    self.label.text = durationString(
                        currentDate: date,
                        startDate: startDate
                    )
                }
        } else {
            self.timer = nil
        }
    }
}

private extension RecordIndicatorView {
    func durationString(
        currentDate: Date,
        startDate: Date
    ) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: startDate, to: currentDate) ?? ""
    }
}
