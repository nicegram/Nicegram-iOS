import Combine
import UIKit

public class GrayscaleLayer: CALayer {
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        enablePublisher: AnyPublisher<Bool, Never>
    ) {
        super.init()
        
        self.isHidden = true
        self.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        self.compositingFilter = "colorBlendMode"
        
        enablePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enable in
                self?.isHidden = !enable
            }
            .store(in: &cancellables)
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
