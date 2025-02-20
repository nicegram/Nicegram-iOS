import UIKit

private let nicegramViewIds = ["AiShortcutsView"]

extension UIGestureRecognizer {
    func isNicegramExclusiveGesture() -> Bool {
        view?.superviewSequence().contains {
            if let accessibilityIdentifier = $0.accessibilityIdentifier {
                nicegramViewIds.contains(accessibilityIdentifier)
            } else {
                false
            }
        } ?? false
    }
}

//  MARK: - Helpers

private extension UIView {
    func superviewSequence() -> some Sequence<UIView> {
        RecursiveSequence(value: self, nextValue: \.superview)
    }
}

private struct RecursiveSequence<T>: Sequence {
    let value: T
    let nextValue: (T) -> T?
    
    func makeIterator() -> RecursiveIterator<T> {
        RecursiveIterator(value: value, nextValue: nextValue)
    }
}

private struct RecursiveIterator<T>: IteratorProtocol {
    var value: T?
    let nextValue: (T) -> T?
    
    mutating func next() -> T? {
        guard let value else {
            return nil
        }
        
        self.value = nextValue(value)
        return value
    }
}
