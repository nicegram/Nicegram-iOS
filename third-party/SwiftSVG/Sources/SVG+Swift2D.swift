import Foundation
import Swift2D

public extension SVG {
    /// Original size of the document image.
    ///
    /// Primarily uses the `viewBox` attribute, and will fallback to the 'pixelSize'
    var originalSize: Size {
        (viewBoxSize ?? pixelSize) ?? .zero
    }

    /// Size of the design in a square 'viewBox'.
    ///
    /// All paths created by this framework are outputted in a 'square'.
    var outputSize: Size {
        let size = (pixelSize ?? viewBoxSize) ?? .zero
        let maxDimension = max(size.width, size.height)
        return Size(width: maxDimension, height: maxDimension)
    }

    /// Size derived from the `viewBox` document attribute
    var viewBoxSize: Size? {
        guard let viewBox else {
            return nil
        }

        let components = viewBox.components(separatedBy: .whitespaces)
        guard components.count == 4 else {
            return nil
        }

        guard let width = Double(components[2]) else {
            return nil
        }

        guard let height = Double(components[3]) else {
            return nil
        }

        return Size(width: width, height: height)
    }

    /// Size derived from the 'width' & 'height' document attributes
    var pixelSize: Size? {
        guard let width, !width.isEmpty else {
            return nil
        }

        guard let height, !height.isEmpty else {
            return nil
        }

        let widthRawValue = width.replacingOccurrences(of: "px", with: "", options: .caseInsensitive, range: nil)
        let heightRawValue = height.replacingOccurrences(of: "px", with: "", options: .caseInsensitive, range: nil)

        guard let w = Double(widthRawValue), let h = Double(heightRawValue) else {
            return nil
        }

        return Size(width: w, height: h)
    }
}
