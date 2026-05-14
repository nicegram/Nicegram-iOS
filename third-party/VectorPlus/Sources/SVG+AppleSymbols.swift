import Foundation
import Swift2D
import SwiftSVG
import XMLCoder

public extension SVG {

    static func encodeDocument(_ document: SVG, encoder: XMLEncoder = XMLEncoder()) throws -> Data {
        let rootAttributes: [String: String] = [
            "version": "1.1",
            "xmlns": "http://www.w3.org/2000/svg",
            "xmlns:xlink": "http://www.w3.org/1999/xlink",
        ]
        let header = XMLHeader(version: 1.0, encoding: "UTF-8", standalone: nil)
        return try encoder.encode(document, withRootKey: "svg", rootAttributes: rootAttributes, header: header)
    }

    static func appleSymbols(path: Path, in rect: Rect) throws -> SVG {
        var document = SVG(width: 3300, height: 2200)
        document.groups = try [.appleSymbolsNotes, .appleSymbolsGuides, .appleSymbols(path: path, in: rect)]
        return document
    }
}

public extension Group {
    static var appleSymbolsNotes: Group {
        var group = Group()

        group.id = "Notes"
        group.rectangles = []
        group.lines = []
        group.texts = []
        group.groups = []

        var artboard = Rectangle(x: 0, y: 0, width: 3300, height: 2200)
        artboard.id = "artboard"
        artboard.style = "fill:white;opacity:1"
        group.rectangles?.append(artboard)

        var topLine = Line(x1: 263, y1: 292, x2: 3036, y2: 292)
        topLine.style = "fill:none;stroke:black;opacity:1;stroke-width:0.5;"
        group.lines?.append(topLine)

        var bottomLine = Line(x1: 263, y1: 1903, x2: 3036, y2: 1903)
        bottomLine.style = "fill:none;stroke:black;opacity:1;stroke-width:0.5;"
        group.lines?.append(bottomLine)

        var text = Text()
        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;font-weight:bold;"
        text.transform = "matrix(1 0 0 1 263 322)"
        text.value = "Weight/Scale Variations"
        group.texts?.append(text)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;text-anchor:middle"
        text.transform = "matrix(1 0 0 1 559.711 322)"
        text.value = "Ultralight"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 856.422 322)"
        text.value = "Thin"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 1153.13 322)"
        text.value = "Light"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 1449.84 322)"
        text.value = "Regular"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 1746.56 322)"
        text.value = "Medium"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 2043.27 322)"
        text.value = "Semibold"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 2339.98 322)"
        text.value = "Bold"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 2636.69 322)"
        text.value = "Heavy"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 2933.4 322)"
        text.value = "Black"
        group.texts?.append(text)

        var path = Path(data: "M 9.24805 0.830078 C 13.5547 0.830078 17.1387 -2.74414 17.1387 -7.05078 C 17.1387 -11.3574 13.5449 -14.9316 9.23828 -14.9316 C 4.94141 -14.9316 1.36719 -11.3574 1.36719 -7.05078 C 1.36719 -2.74414 4.95117 0.830078 9.24805 0.830078 Z M 9.24805 -0.654297 C 5.70312 -0.654297 2.87109 -3.49609 2.87109 -7.05078 C 2.87109 -10.6055 5.69336 -13.4473 9.23828 -13.4473 C 12.793 -13.4473 15.6348 -10.6055 15.6445 -7.05078 C 15.6543 -3.49609 12.8027 -0.654297 9.24805 -0.654297 Z M 9.22852 -3.42773 C 9.69727 -3.42773 9.9707 -3.74023 9.9707 -4.25781 L 9.9707 -6.31836 L 12.1973 -6.31836 C 12.6953 -6.31836 13.0371 -6.57227 13.0371 -7.04102 C 13.0371 -7.51953 12.7148 -7.7832 12.1973 -7.7832 L 9.9707 -7.7832 L 9.9707 -10.0098 C 9.9707 -10.5273 9.69727 -10.8496 9.22852 -10.8496 C 8.75977 -10.8496 8.50586 -10.5078 8.50586 -10.0098 L 8.50586 -7.7832 L 6.29883 -7.7832 C 5.78125 -7.7832 5.44922 -7.51953 5.44922 -7.04102 C 5.44922 -6.57227 5.80078 -6.31836 6.29883 -6.31836 L 8.50586 -6.31836 L 8.50586 -4.25781 C 8.50586 -3.75977 8.75977 -3.42773 9.22852 -3.42773 Z")
        var subGroup = Group("", path: path, transform: "matrix(1 0 0 1 263 1933)")
        group.groups?.append(subGroup)

        path.data = "M 11.709 2.91016 C 17.1582 2.91016 21.6699 -1.60156 21.6699 -7.05078 C 21.6699 -12.4902 17.1484 -17.0117 11.6992 -17.0117 C 6.25977 -17.0117 1.74805 -12.4902 1.74805 -7.05078 C 1.74805 -1.60156 6.26953 2.91016 11.709 2.91016 Z M 11.709 1.25 C 7.09961 1.25 3.41797 -2.44141 3.41797 -7.05078 C 3.41797 -11.6504 7.08984 -15.3516 11.6992 -15.3516 C 16.3086 -15.3516 20 -11.6504 20.0098 -7.05078 C 20.0195 -2.44141 16.3184 1.25 11.709 1.25 Z M 11.6895 -2.41211 C 12.207 -2.41211 12.5195 -2.77344 12.5195 -3.33984 L 12.5195 -6.23047 L 15.5762 -6.23047 C 16.123 -6.23047 16.5039 -6.51367 16.5039 -7.03125 C 16.5039 -7.55859 16.1426 -7.86133 15.5762 -7.86133 L 12.5195 -7.86133 L 12.5195 -10.9277 C 12.5195 -11.5039 12.207 -11.8555 11.6895 -11.8555 C 11.1719 -11.8555 10.8789 -11.4844 10.8789 -10.9277 L 10.8789 -7.86133 L 7.83203 -7.86133 C 7.26562 -7.86133 6.89453 -7.55859 6.89453 -7.03125 C 6.89453 -6.51367 7.28516 -6.23047 7.83203 -6.23047 L 10.8789 -6.23047 L 10.8789 -3.33984 C 10.8789 -2.79297 11.1719 -2.41211 11.6895 -2.41211 Z"
        subGroup.paths = [path]
        subGroup.transform = "matrix(1 0 0 1 281.506 1933)"
        group.groups?.append(subGroup)

        path.data = "M 14.9707 5.67383 C 21.9336 5.67383 27.6953 -0.078125 27.6953 -7.04102 C 27.6953 -14.0039 21.9238 -19.7559 14.9609 -19.7559 C 8.00781 -19.7559 2.25586 -14.0039 2.25586 -7.04102 C 2.25586 -0.078125 8.01758 5.67383 14.9707 5.67383 Z M 14.9707 3.85742 C 8.93555 3.85742 4.08203 -1.00586 4.08203 -7.04102 C 4.08203 -13.0762 8.92578 -17.9395 14.9609 -17.9395 C 21.0059 -17.9395 25.8594 -13.0762 25.8691 -7.04102 C 25.8789 -1.00586 21.0156 3.85742 14.9707 3.85742 Z M 14.9512 -1.06445 C 15.5176 -1.06445 15.8691 -1.45508 15.8691 -2.06055 L 15.8691 -6.13281 L 20.1074 -6.13281 C 20.6934 -6.13281 21.1133 -6.46484 21.1133 -7.02148 C 21.1133 -7.59766 20.7227 -7.93945 20.1074 -7.93945 L 15.8691 -7.93945 L 15.8691 -12.1875 C 15.8691 -12.8027 15.5176 -13.1934 14.9512 -13.1934 C 14.3848 -13.1934 14.0625 -12.7832 14.0625 -12.1875 L 14.0625 -7.93945 L 9.83398 -7.93945 C 9.21875 -7.93945 8.80859 -7.59766 8.80859 -7.02148 C 8.80859 -6.46484 9.23828 -6.13281 9.83398 -6.13281 L 14.0625 -6.13281 L 14.0625 -2.06055 C 14.0625 -1.47461 14.3848 -1.06445 14.9512 -1.06445 Z"
        subGroup.paths = [path]
        subGroup.transform = "matrix(1 0 0 1 304.924 1933)"
        group.groups?.append(subGroup)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;font-weight:bold;"
        text.transform = "matrix(1 0 0 1 263 1953)"
        text.value = "Design Variations"
        group.texts?.append(text)

        text.style = "none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;"
        text.transform = "matrix(1 0 0 1 263 1971)"
        text.value = "Symbols are supported in up to nine weights and three scales."
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 263 1989)"
        text.value = "For optimal layout with text and other symbols, vertically align"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 263 2007)"
        text.value = "symbols with the adjacent text."
        group.texts?.append(text)

        var rect = Rectangle(x: 776, y: 1919, width: 3, height: 14)
        rect.style = "fill:#00AEEF;stroke:none;opacity:0.4;"
        group.rectangles?.append(rect)

        path.data = "M 10.5273 0 L 12.373 0 L 7.17773 -14.0918 L 5.43945 -14.0918 L 0.244141 0 L 2.08984 0 L 3.50586 -4.0332 L 9.11133 -4.0332 Z M 6.2793 -11.9531 L 6.33789 -11.9531 L 8.59375 -5.52734 L 4.02344 -5.52734 Z"
        subGroup.paths = [path]
        subGroup.transform = "matrix(1 0 0 1 779 1933)"
        group.groups?.append(subGroup)

        rect.x = 791.617
        group.rectangles?.append(rect)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;font-weight:bold;"
        text.transform = "matrix(1 0 0 1 776 1953)"
        text.value = "Margins"
        group.texts?.append(text)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;"
        text.transform = "matrix(1 0 0 1 776 1971)"
        text.value = "Leading and trailing margins on the left and right side of each symbol"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 776 1989)"
        text.value = "can be adjusted by modifying the width of the blue rectangles."
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 776 2007)"
        text.value = "Modifications are automatically applied proportionally to all"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 776 2025)"
        text.value = "scales and weights."
        group.texts?.append(text)

        path.data = "M 2.83203 3.11523 L 4.375 4.6582 C 5.22461 5.48828 6.19141 5.41992 7.06055 4.46289 L 17.2754 -6.66016 C 17.7051 -6.36719 18.0957 -6.37695 18.5645 -6.47461 L 19.6094 -6.68945 L 20.3027 -5.99609 L 20.2539 -5.47852 C 20.1855 -4.95117 20.3516 -4.53125 20.8496 -4.0332 L 21.6602 -3.22266 C 22.168 -2.71484 22.8223 -2.68555 23.3008 -3.16406 L 26.5527 -6.41602 C 27.0312 -6.89453 27.0117 -7.54883 26.5039 -8.05664 L 25.6836 -8.87695 C 25.1855 -9.375 24.7754 -9.55078 24.2383 -9.47266 L 23.7109 -9.41406 L 23.0566 -10.0781 L 23.3398 -11.2207 C 23.4863 -11.7871 23.3398 -12.2559 22.7148 -12.8613 L 20.3027 -15.2539 C 16.7578 -18.7793 12.2266 -18.6719 9.11133 -15.5371 C 8.69141 -15.1074 8.64258 -14.5215 8.91602 -14.0918 C 9.15039 -13.7207 9.62891 -13.4961 10.2734 -13.6621 C 11.7871 -14.043 13.3008 -13.9258 14.7852 -12.9199 L 14.1602 -11.3379 C 13.9258 -10.752 13.9453 -10.2734 14.1797 -9.83398 L 3.01758 0.439453 C 2.08008 1.30859 1.97266 2.25586 2.83203 3.11523 Z M 10.6738 -15.1465 C 13.3398 -17.1387 16.6504 -16.8262 19.0527 -14.4141 L 21.6797 -11.8066 C 21.9141 -11.5723 21.9434 -11.3867 21.8848 -11.0938 L 21.5039 -9.53125 L 23.0762 -7.95898 L 24.043 -8.04688 C 24.3262 -8.07617 24.4141 -8.05664 24.6387 -7.83203 L 25.2637 -7.20703 L 22.5098 -4.46289 L 21.8848 -5.07812 C 21.6602 -5.30273 21.6406 -5.40039 21.6699 -5.68359 L 21.7578 -6.64062 L 20.1953 -8.20312 L 18.5742 -7.89062 C 18.291 -7.83203 18.1445 -7.83203 17.9102 -8.07617 L 15.7324 -10.2539 C 15.5078 -10.4883 15.4785 -10.625 15.6055 -10.9473 L 16.5527 -13.2227 C 14.9512 -14.7559 12.8418 -15.6055 10.8008 -14.9512 C 10.7129 -14.9219 10.6445 -14.9414 10.6152 -14.9805 C 10.5859 -15.0293 10.5859 -15.0781 10.6738 -15.1465 Z M 4.10156 2.41211 C 3.61328 1.91406 3.78906 1.61133 4.12109 1.30859 L 15.0781 -8.80859 L 16.3086 -7.57812 L 6.15234 3.34961 C 5.84961 3.68164 5.46875 3.7793 5.06836 3.37891 Z"
        subGroup.paths = [path]
        subGroup.transform = "matrix(1 0 0 1 1289 1933)"
        group.groups?.append(subGroup)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;font-weight:bold;"
        text.transform = "matrix(1 0 0 1 1289 1953)"
        text.value = "Exporting"
        group.texts?.append(text)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;"
        text.transform = "matrix(1 0 0 1 1289 1971)"
        text.value = "Symbols should be outlined when exporting to ensure the"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 1289 1989)"
        text.value = "design is preserved when submitting to Xcode."
        group.texts?.append(text)

        text.id = "template-version"
        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;text-anchor:end;"
        text.transform = "matrix(1 0 0 1 3036 1933)"
        text.value = "Template v.2.0"
        group.texts?.append(text)

        text.id = nil
        text.transform = "matrix(1 0 0 1 3036 1969)"
        text.value = "Typeset at 100 points"
        group.texts?.append(text)

        text.style = "stroke:none;fill:black;font-family:-apple-system,\"SF Pro Display\",\"SF Pro Text\",Helvetica,sans-serif;"
        text.transform = "matrix(1 0 0 1 263 726)"
        text.value = "Small"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 263 1156)"
        text.value = "Medium"
        group.texts?.append(text)

        text.transform = "matrix(1 0 0 1 263 1586)"
        text.value = "Large"
        group.texts?.append(text)

        return group
    }

    static var appleSymbolsGuides: Group {
        var group = Group()

        group.id = "Guides"
        group.groups = []
        group.lines = []

        var hRef = Group()
        hRef.id = "H-reference"
        hRef.style = "fill:#27AAE1;stroke:none;"
        hRef.transform = "matrix(1 0 0 1 339 696)"
        hRef.paths = [Path(data: "M 54.9316 0 L 57.666 0 L 30.5664 -70.459 L 28.0762 -70.459 L 0.976562 0 L 3.66211 0 L 12.9395 -24.4629 L 45.7031 -24.4629 Z M 29.1992 -67.0898 L 29.4434 -67.0898 L 44.8242 -26.709 L 13.8184 -26.709 Z")]
        group.groups?.append(hRef)

        var baseline = Line(x1: 263, y1: 696, x2: 3036, y2: 696)
        baseline.id = "Baseline-S"
        baseline.style = "fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.577;"
        group.lines?.append(baseline)

        var capline = Line(x1: 263, y1: 625.541, x2: 3036, y2: 625.541)
        capline.id = "Capline-S"
        capline.style = "fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.577;"
        group.lines?.append(capline)

        hRef.transform = "matrix(1 0 0 1 339 1126)"
        hRef.paths = [Path(data: "M 54.9316 0 L 57.666 0 L 30.5664 -70.459 L 28.0762 -70.459 L 0.976562 0 L 3.66211 0 L 12.9395 -24.4629 L 45.7031 -24.4629 Z M 29.1992 -67.0898 L 29.4434 -67.0898 L 44.8242 -26.709 L 13.8184 -26.709 Z")]
        group.groups?.append(hRef)

        baseline.id = "Baseline-M"
        baseline.y1 = 1126
        baseline.y2 = 1126
        group.lines?.append(baseline)

        capline.id = "Capline-M"
        capline.y1 = 1055.54
        capline.y2 = 1055.54
        group.lines?.append(capline)

        hRef.transform = "matrix(1 0 0 1 339 1556)"
        hRef.paths = [Path(data: "M 54.9316 0 L 57.666 0 L 30.5664 -70.459 L 28.0762 -70.459 L 0.976562 0 L 3.66211 0 L 12.9395 -24.4629 L 45.7031 -24.4629 Z M 29.1992 -67.0898 L 29.4434 -67.0898 L 44.8242 -26.709 L 13.8184 -26.709 Z")]
        group.groups?.append(hRef)

        baseline.id = "Baseline-L"
        baseline.y1 = 1556
        baseline.y2 = 1556
        group.lines?.append(baseline)

        capline.id = "Capline-L"
        capline.y1 = 1485.54
        capline.y2 = 1485.54
        group.lines?.append(capline)

        var margin = Line(x1: 1399.72, y1: 1030.79, x2: 1399.72, y2: 1150.12)
        margin.id = "left-margin"
        margin.style = "fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;"
        group.lines?.append(margin)

        margin = Line(x1: 1499.97, y1: 1030.79, x2: 1499.97, y2: 1150.12)
        margin.id = "right-margin"
        margin.style = "fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;"
        group.lines?.append(margin)

        return group
    }

    static func appleSymbols(path: Path, in rect: Rect) throws -> Group {
        var group = Group()

        group.id = "Symbols"

        let translations: [(name: String, size: Float, center: Point)] = [
            ("Ultralight-S", 0.75, .init(x: 559.0, y: 661.0)),
            ("Thin-S", 0.76, .init(x: 857.0, y: 661.0)),
            ("Light-S", 0.78, .init(x: 1153.0, y: 661.0)),
            ("Regular-S", 0.79, .init(x: 1449.5, y: 661.0)),
            ("Medium-S", 0.80, .init(x: 1747.0, y: 661.0)),
            ("Semibold-S", 0.81, .init(x: 2043.0, y: 661.0)),
            ("Bold-S", 0.82, .init(x: 2340.0, y: 661.0)),
            ("Heavy-S", 0.85, .init(x: 2636.5, y: 661.0)),
            ("Black-S", 0.86, .init(x: 2933.0, y: 661.0)),
            ("Ultralight-M", 0.95, .init(x: 559.0, y: 1091.0)),
            ("Thin-M", 0.96, .init(x: 857.0, y: 1091.0)),
            ("Light-M", 0.98, .init(x: 1153.0, y: 1091.0)),
            ("Regular-M", 1.00, .init(x: 1449.5, y: 1091.0)),
            ("Medium-M", 1.02, .init(x: 1747.0, y: 1091.0)),
            ("Semibold-M", 1.03, .init(x: 2043.0, y: 1091.0)),
            ("Bold-M", 1.05, .init(x: 2340.0, y: 1091.0)),
            ("Heavy-M", 1.07, .init(x: 2636.5, y: 1091.0)),
            ("Black-M", 1.10, .init(x: 2933.0, y: 1091.0)),
            ("Ultralight-L", 1.22, .init(x: 559.0, y: 1521.0)),
            ("Thin-L", 1.24, .init(x: 857.0, y: 1521.0)),
            ("Light-L", 1.26, .init(x: 1153.0, y: 1521.0)),
            ("Regular-L", 1.28, .init(x: 1449.5, y: 1521.0)),
            ("Medium-L", 1.30, .init(x: 1747.0, y: 1521.0)),
            ("Semibold-L", 1.31, .init(x: 2043.0, y: 1521.0)),
            ("Bold-L", 1.33, .init(x: 2340.0, y: 1521.0)),
            ("Heavy-L", 1.36, .init(x: 2636.5, y: 1521.0)),
            ("Black-L", 1.39, .init(x: 2933.0, y: 1521.0)),
        ]

        group.groups = try translations.map { symbol -> Group in
            let size = Size(width: 100.0 * symbol.size, height: 100.0 * symbol.size)
            let to = Rect(origin: .zero, size: size)
            let commands = try path.commands().map { $0.translate(from: rect, to: to) }
            let p = Path(commands: commands)
            let matrixOrigin = Point(x: symbol.center.x - size.width / 2.0, y: symbol.center.y - size.height / 2.0)
            let matrix: Transformation = .matrix(a: 1, b: 0, c: 0, d: 1, e: matrixOrigin.x, f: matrixOrigin.y)
            return Group(symbol.name, path: p, transform: matrix.description)
        }

        return group
    }
}

private extension Group {
    init(_ id: String, path: Path, transform: String) {
        self.init()
        self.id = id
        self.transform = transform
        paths = [path]
    }
}
