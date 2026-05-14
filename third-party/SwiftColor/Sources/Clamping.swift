@propertyWrapper
public struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>

    public init(wrappedValue value: Value, _ range: ClosedRange<Value>) {
        precondition(range.contains(value))
        self.value = value
        self.range = range
    }

    public var wrappedValue: Value {
        get {
            value
        }
        set(newValue) {
            value = min(max(range.lowerBound, newValue), range.upperBound)
        }
    }
}
