import UIKit
import Display
import ComponentFlow

public class NGRecordIndicatorView: UIView {
    private let contentView = UIView()
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16.0, weight: .regular)
        
        return label
    }()
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(bundleImageName: "RecordIndicator")

        return imageView
    }()
    private let textHeight: CGFloat = 20.0
    private let sideInset: CGFloat = 8.0
    private let verticalInset: CGFloat = 4.0
    private let iconSpacing: CGFloat = 4.0
    private var actualSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = (textHeight + verticalInset * 2) / 2
        contentView.backgroundColor = UIColor(hexString: "FF453A")
                
        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func animateIn() {
        self.layer.animateScale(from: 0.001, to: 1.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
    }
    
    public func animateOut(completion: @escaping () -> Void) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { _ in
            completion()
        })
        self.layer.animateScale(from: 1.0, to: 0.001, duration: 0.2, removeOnCompletion: false)
    }
    
    public func update(
        text: String,
        constrainedWidth: CGFloat = 75.0,
        transition: ComponentTransition
    ) -> CGSize {
        label.text = text

        let iconSize = self.imageView.image?.size ?? CGSize(width: 20.0, height: 20.0)
        
        let maxSize = CGSize(width: constrainedWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = text.boundingRect(
            with: maxSize,
            options: .usesLineFragmentOrigin,
            attributes: [.font: label.font ?? UIFont()],
            context: nil
        )
        let textSize = CGSize(width: ceil(max(boundingRect.width, 35.0)), height: textHeight)
        
        let size = CGSize(width: iconSize.width + iconSpacing + textSize.width + sideInset * 2.0, height: textSize.height + verticalInset * 2.0)
        actualSize = size.width > actualSize.width ? size : actualSize
        
        transition.setFrame(view: self.contentView, frame: CGRect(origin: CGPoint(), size: actualSize))
        
        transition.setFrame(view: self.imageView, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((actualSize.height - iconSize.height) * 0.5) + 4.0, y: verticalInset + floorToScreenPixels((textSize.height - iconSize.height) * 0.5)), size: iconSize))
        
        transition.setFrame(view: self.label, frame: CGRect(origin: CGPoint(x: sideInset + iconSize.width + iconSpacing, y: verticalInset), size: textSize))
        
        return actualSize
    }
}
