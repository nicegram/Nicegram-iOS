import UIKit

public class GrayscaleApplier {
    
    private var grayscaleLayer: CALayer?
    
    public init() {}
}

public extension GrayscaleApplier {
    func onLayoutUpdated(
        apply: Bool,
        frame: CGRect,
        superlayer: CALayer?
    ) {
        if apply {
            let grayscaleLayer: CALayer
            if let _grayscaleLayer = self.grayscaleLayer {
                grayscaleLayer = _grayscaleLayer
            } else {
                grayscaleLayer = CALayer()
                grayscaleLayer.compositingFilter = "colorBlendMode"
                grayscaleLayer.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
                
                self.grayscaleLayer = grayscaleLayer
                
                superlayer?.addSublayer(grayscaleLayer)
            }
            
            grayscaleLayer.frame = frame
        } else {
            self.grayscaleLayer?.removeFromSuperlayer()
            self.grayscaleLayer = nil
        }
    }
}
