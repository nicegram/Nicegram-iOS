import Foundation

public extension Pigment {
    @available(*, deprecated, renamed: "Name")
    typealias Keyword = Name

    enum Name: String, CaseIterable {
        case aliceBlue
        case antiqueWhite
        case aqua
        case aquamarine
        case azure
        case beige
        case bisque
        case black
        case blanchedAlmond
        case blue
        case blueViolet
        case brown
        case burlywood
        case cadetBlue
        case chartreuse
        case chocolate
        case coral
        case cornflowerBlue
        case cornsilk
        case crimson
        case cyan
        case darkBlue
        case darkCyan
        case darkGoldenrod
        case darkGray
        case darkGreen
        case darkGrey
        case darkKhaki
        case darkMagenta
        case darkOliveGreen
        case darkOrange
        case darkOrchid
        case darkRed
        case darkSalmon
        case darkSeagreen
        case darkSlateBlue
        case darkSlateGray
        case darkSlateGrey
        case darkTurquoise
        case darkViolet
        case deepPink
        case deepSkyblue
        case dimGray
        case dimGrey
        case dodgerBlue
        case firebrick
        case floralWhite
        case forestGreen
        case fuchsia
        case gainsboro
        case ghostWhite
        case gold
        case goldenrod
        case gray
        case green
        case greenYellow
        case grey
        case honeydew
        case hotPink
        case indianRed
        case indigo
        case ivory
        case khaki
        case lavender
        case lavenderBlush
        case lawnGreen
        case lemonChiffon
        case lightBlue
        case lightCoral
        case lightCyan
        case lightGoldenrodYellow
        case lightGray
        case lightGreen
        case lightGrey
        case lightPink
        case lightSalmon
        case lightSeagreen
        case lightSkyBlue
        case lightSlateGray
        case lightSlateGrey
        case lightSteelBlue
        case lightYellow
        case lime
        case limeGreen
        case linen
        case magenta
        case maroon
        case mediumAquamarine
        case mediumBlue
        case mediumOrchid
        case mediumPurple
        case mediumSeagreen
        case mediumSlateBlue
        case mediumSpringGreen
        case mediumTurquoise
        case mediumVioletRed
        case midnightBlue
        case mintCream
        case mistyRose
        case moccasin
        case navajoWhite
        case navy
        case oldLace
        case olive
        case oliveDrab
        case orange
        case orangeRed
        case orchid
        case paleGoldenrod
        case paleGreen
        case paleTurquoise
        case paleVioletRed
        case papayaWhip
        case peachPuff
        case peru
        case pink
        case plum
        case powderBlue
        case purple
        case red
        case rosyBrown
        case royalBlue
        case saddleBrown
        case salmon
        case sandyBrown
        case seagreen
        case seashell
        case sienna
        case silver
        case skyBlue
        case slateBlue
        case slateGray
        case slateGrey
        case snow
        case springGreen
        case steelBlue
        case tan
        case teal
        case thistle
        case tomato
        case turquoise
        case violet
        case wheat
        case white
        case whitesmoke
        case yellow
        case yellowGreen

        public var rgb: (red: Int, green: Int, blue: Int) {
            switch self {
            case .aliceBlue: (240, 248, 255)
            case .antiqueWhite: (250, 235, 215)
            case .aqua: (0, 255, 255)
            case .aquamarine: (127, 255, 212)
            case .azure: (240, 255, 255)
            case .beige: (245, 245, 220)
            case .bisque: (255, 228, 196)
            case .black: (0, 0, 0)
            case .blanchedAlmond: (255, 235, 205)
            case .blue: (0, 0, 255)
            case .blueViolet: (138, 43, 226)
            case .brown: (165, 42, 42)
            case .burlywood: (222, 184, 135)
            case .cadetBlue: (95, 158, 160)
            case .chartreuse: (127, 255, 0)
            case .chocolate: (210, 105, 30)
            case .coral: (255, 127, 80)
            case .cornflowerBlue: (100, 149, 237)
            case .cornsilk: (255, 248, 220)
            case .crimson: (220, 20, 60)
            case .cyan: (0, 255, 255)
            case .darkBlue: (0, 0, 139)
            case .darkCyan: (0, 139, 139)
            case .darkGoldenrod: (184, 134, 11)
            case .darkGray: (169, 169, 169)
            case .darkGreen: (0, 100, 0)
            case .darkGrey: (169, 169, 169)
            case .darkKhaki: (189, 183, 107)
            case .darkMagenta: (139, 0, 139)
            case .darkOliveGreen: (85, 107, 47)
            case .darkOrange: (255, 140, 0)
            case .darkOrchid: (153, 50, 204)
            case .darkRed: (139, 0, 0)
            case .darkSalmon: (233, 150, 122)
            case .darkSeagreen: (143, 188, 143)
            case .darkSlateBlue: (72, 61, 139)
            case .darkSlateGray: (47, 79, 79)
            case .darkSlateGrey: (47, 79, 79)
            case .darkTurquoise: (0, 206, 209)
            case .darkViolet: (148, 0, 211)
            case .deepPink: (255, 20, 147)
            case .deepSkyblue: (0, 191, 255)
            case .dimGray: (105, 105, 105)
            case .dimGrey: (105, 105, 105)
            case .dodgerBlue: (30, 144, 255)
            case .firebrick: (178, 34, 34)
            case .floralWhite: (255, 250, 240)
            case .forestGreen: (34, 139, 34)
            case .fuchsia: (255, 0, 255)
            case .gainsboro: (220, 220, 220)
            case .ghostWhite: (248, 248, 255)
            case .gold: (255, 215, 0)
            case .goldenrod: (218, 165, 32)
            case .gray: (128, 128, 128)
            case .green: (0, 128, 0)
            case .greenYellow: (173, 255, 47)
            case .grey: (128, 128, 128)
            case .honeydew: (240, 255, 240)
            case .hotPink: (255, 105, 180)
            case .indianRed: (205, 92, 92)
            case .indigo: (75, 0, 130)
            case .ivory: (255, 255, 240)
            case .khaki: (240, 230, 140)
            case .lavender: (230, 230, 250)
            case .lavenderBlush: (255, 240, 245)
            case .lawnGreen: (124, 252, 0)
            case .lemonChiffon: (255, 250, 205)
            case .lightBlue: (173, 216, 230)
            case .lightCoral: (240, 128, 128)
            case .lightCyan: (224, 255, 255)
            case .lightGoldenrodYellow: (250, 250, 210)
            case .lightGray: (211, 211, 211)
            case .lightGreen: (144, 238, 144)
            case .lightGrey: (211, 211, 211)
            case .lightPink: (255, 182, 193)
            case .lightSalmon: (255, 160, 122)
            case .lightSeagreen: (32, 178, 170)
            case .lightSkyBlue: (135, 206, 250)
            case .lightSlateGray: (119, 136, 153)
            case .lightSlateGrey: (119, 136, 153)
            case .lightSteelBlue: (176, 196, 222)
            case .lightYellow: (255, 255, 224)
            case .lime: (0, 255, 0)
            case .limeGreen: (50, 205, 50)
            case .linen: (250, 240, 230)
            case .magenta: (255, 0, 255)
            case .maroon: (128, 0, 0)
            case .mediumAquamarine: (102, 205, 170)
            case .mediumBlue: (0, 0, 205)
            case .mediumOrchid: (186, 85, 211)
            case .mediumPurple: (147, 112, 219)
            case .mediumSeagreen: (60, 179, 113)
            case .mediumSlateBlue: (123, 104, 238)
            case .mediumSpringGreen: (0, 250, 154)
            case .mediumTurquoise: (72, 209, 204)
            case .mediumVioletRed: (199, 21, 133)
            case .midnightBlue: (25, 25, 112)
            case .mintCream: (245, 255, 250)
            case .mistyRose: (255, 228, 225)
            case .moccasin: (255, 228, 181)
            case .navajoWhite: (255, 222, 173)
            case .navy: (0, 0, 128)
            case .oldLace: (253, 245, 230)
            case .olive: (128, 128, 0)
            case .oliveDrab: (107, 142, 35)
            case .orange: (255, 165, 0)
            case .orangeRed: (255, 69, 0)
            case .orchid: (218, 112, 214)
            case .paleGoldenrod: (238, 232, 170)
            case .paleGreen: (152, 251, 152)
            case .paleTurquoise: (175, 238, 238)
            case .paleVioletRed: (219, 112, 147)
            case .papayaWhip: (255, 239, 213)
            case .peachPuff: (255, 218, 185)
            case .peru: (205, 133, 63)
            case .pink: (255, 192, 203)
            case .plum: (221, 160, 221)
            case .powderBlue: (176, 224, 230)
            case .purple: (128, 0, 128)
            case .red: (255, 0, 0)
            case .rosyBrown: (188, 143, 143)
            case .royalBlue: (65, 105, 225)
            case .saddleBrown: (139, 69, 19)
            case .salmon: (250, 128, 114)
            case .sandyBrown: (244, 164, 96)
            case .seagreen: (46, 139, 87)
            case .seashell: (255, 245, 238)
            case .sienna: (160, 82, 45)
            case .silver: (192, 192, 192)
            case .skyBlue: (135, 206, 235)
            case .slateBlue: (106, 90, 205)
            case .slateGray: (112, 128, 144)
            case .slateGrey: (112, 128, 144)
            case .snow: (255, 250, 250)
            case .springGreen: (0, 255, 127)
            case .steelBlue: (70, 130, 180)
            case .tan: (210, 180, 140)
            case .teal: (0, 128, 128)
            case .thistle: (216, 191, 216)
            case .tomato: (255, 99, 71)
            case .turquoise: (64, 224, 208)
            case .violet: (238, 130, 238)
            case .wheat: (245, 222, 179)
            case .white: (255, 255, 255)
            case .whitesmoke: (245, 245, 245)
            case .yellow: (255, 255, 0)
            case .yellowGreen: (154, 205, 50)
            }
        }

        public var pigment: Pigment {
            switch self {
            case .aliceBlue: Pigment(240, 248, 255, alpha: 1.0)
            case .antiqueWhite: Pigment(250, 235, 215, alpha: 1.0)
            case .aqua: Pigment(0, 255, 255, alpha: 1.0)
            case .aquamarine: Pigment(127, 255, 212, alpha: 1.0)
            case .azure: Pigment(240, 255, 255, alpha: 1.0)
            case .beige: Pigment(245, 245, 220, alpha: 1.0)
            case .bisque: Pigment(255, 228, 196, alpha: 1.0)
            case .black: Pigment(0, 0, 0, alpha: 1.0)
            case .blanchedAlmond: Pigment(255, 235, 205, alpha: 1.0)
            case .blue: Pigment(0, 0, 255, alpha: 1.0)
            case .blueViolet: Pigment(138, 43, 226, alpha: 1.0)
            case .brown: Pigment(165, 42, 42, alpha: 1.0)
            case .burlywood: Pigment(222, 184, 135, alpha: 1.0)
            case .cadetBlue: Pigment(95, 158, 160, alpha: 1.0)
            case .chartreuse: Pigment(127, 255, 0, alpha: 1.0)
            case .chocolate: Pigment(210, 105, 30, alpha: 1.0)
            case .coral: Pigment(255, 127, 80, alpha: 1.0)
            case .cornflowerBlue: Pigment(100, 149, 237, alpha: 1.0)
            case .cornsilk: Pigment(255, 248, 220, alpha: 1.0)
            case .crimson: Pigment(220, 20, 60, alpha: 1.0)
            case .cyan: Pigment(0, 255, 255, alpha: 1.0)
            case .darkBlue: Pigment(0, 0, 139, alpha: 1.0)
            case .darkCyan: Pigment(0, 139, 139, alpha: 1.0)
            case .darkGoldenrod: Pigment(184, 134, 11, alpha: 1.0)
            case .darkGray: Pigment(169, 169, 169, alpha: 1.0)
            case .darkGreen: Pigment(0, 100, 0, alpha: 1.0)
            case .darkGrey: Pigment(169, 169, 169, alpha: 1.0)
            case .darkKhaki: Pigment(189, 183, 107, alpha: 1.0)
            case .darkMagenta: Pigment(139, 0, 139, alpha: 1.0)
            case .darkOliveGreen: Pigment(85, 107, 47, alpha: 1.0)
            case .darkOrange: Pigment(255, 140, 0, alpha: 1.0)
            case .darkOrchid: Pigment(153, 50, 204, alpha: 1.0)
            case .darkRed: Pigment(139, 0, 0, alpha: 1.0)
            case .darkSalmon: Pigment(233, 150, 122, alpha: 1.0)
            case .darkSeagreen: Pigment(143, 188, 143, alpha: 1.0)
            case .darkSlateBlue: Pigment(72, 61, 139, alpha: 1.0)
            case .darkSlateGray: Pigment(47, 79, 79, alpha: 1.0)
            case .darkSlateGrey: Pigment(47, 79, 79, alpha: 1.0)
            case .darkTurquoise: Pigment(0, 206, 209, alpha: 1.0)
            case .darkViolet: Pigment(148, 0, 211, alpha: 1.0)
            case .deepPink: Pigment(255, 20, 147, alpha: 1.0)
            case .deepSkyblue: Pigment(0, 191, 255, alpha: 1.0)
            case .dimGray: Pigment(105, 105, 105, alpha: 1.0)
            case .dimGrey: Pigment(105, 105, 105, alpha: 1.0)
            case .dodgerBlue: Pigment(30, 144, 255, alpha: 1.0)
            case .firebrick: Pigment(178, 34, 34, alpha: 1.0)
            case .floralWhite: Pigment(255, 250, 240, alpha: 1.0)
            case .forestGreen: Pigment(34, 139, 34, alpha: 1.0)
            case .fuchsia: Pigment(255, 0, 255, alpha: 1.0)
            case .gainsboro: Pigment(220, 220, 220, alpha: 1.0)
            case .ghostWhite: Pigment(248, 248, 255, alpha: 1.0)
            case .gold: Pigment(255, 215, 0, alpha: 1.0)
            case .goldenrod: Pigment(218, 165, 32, alpha: 1.0)
            case .gray: Pigment(128, 128, 128, alpha: 1.0)
            case .green: Pigment(0, 128, 0, alpha: 1.0)
            case .greenYellow: Pigment(173, 255, 47, alpha: 1.0)
            case .grey: Pigment(128, 128, 128, alpha: 1.0)
            case .honeydew: Pigment(240, 255, 240, alpha: 1.0)
            case .hotPink: Pigment(255, 105, 180, alpha: 1.0)
            case .indianRed: Pigment(205, 92, 92, alpha: 1.0)
            case .indigo: Pigment(75, 0, 130, alpha: 1.0)
            case .ivory: Pigment(255, 255, 240, alpha: 1.0)
            case .khaki: Pigment(240, 230, 140, alpha: 1.0)
            case .lavender: Pigment(230, 230, 250, alpha: 1.0)
            case .lavenderBlush: Pigment(255, 240, 245, alpha: 1.0)
            case .lawnGreen: Pigment(124, 252, 0, alpha: 1.0)
            case .lemonChiffon: Pigment(255, 250, 205, alpha: 1.0)
            case .lightBlue: Pigment(173, 216, 230, alpha: 1.0)
            case .lightCoral: Pigment(240, 128, 128, alpha: 1.0)
            case .lightCyan: Pigment(224, 255, 255, alpha: 1.0)
            case .lightGoldenrodYellow: Pigment(250, 250, 210, alpha: 1.0)
            case .lightGray: Pigment(211, 211, 211, alpha: 1.0)
            case .lightGreen: Pigment(144, 238, 144, alpha: 1.0)
            case .lightGrey: Pigment(211, 211, 211, alpha: 1.0)
            case .lightPink: Pigment(255, 182, 193, alpha: 1.0)
            case .lightSalmon: Pigment(255, 160, 122, alpha: 1.0)
            case .lightSeagreen: Pigment(32, 178, 170, alpha: 1.0)
            case .lightSkyBlue: Pigment(135, 206, 250, alpha: 1.0)
            case .lightSlateGray: Pigment(119, 136, 153, alpha: 1.0)
            case .lightSlateGrey: Pigment(119, 136, 153, alpha: 1.0)
            case .lightSteelBlue: Pigment(176, 196, 222, alpha: 1.0)
            case .lightYellow: Pigment(255, 255, 224, alpha: 1.0)
            case .lime: Pigment(0, 255, 0, alpha: 1.0)
            case .limeGreen: Pigment(50, 205, 50, alpha: 1.0)
            case .linen: Pigment(250, 240, 230, alpha: 1.0)
            case .magenta: Pigment(255, 0, 255, alpha: 1.0)
            case .maroon: Pigment(128, 0, 0, alpha: 1.0)
            case .mediumAquamarine: Pigment(102, 205, 170, alpha: 1.0)
            case .mediumBlue: Pigment(0, 0, 205, alpha: 1.0)
            case .mediumOrchid: Pigment(186, 85, 211, alpha: 1.0)
            case .mediumPurple: Pigment(147, 112, 219, alpha: 1.0)
            case .mediumSeagreen: Pigment(60, 179, 113, alpha: 1.0)
            case .mediumSlateBlue: Pigment(123, 104, 238, alpha: 1.0)
            case .mediumSpringGreen: Pigment(0, 250, 154, alpha: 1.0)
            case .mediumTurquoise: Pigment(72, 209, 204, alpha: 1.0)
            case .mediumVioletRed: Pigment(199, 21, 133, alpha: 1.0)
            case .midnightBlue: Pigment(25, 25, 112, alpha: 1.0)
            case .mintCream: Pigment(245, 255, 250, alpha: 1.0)
            case .mistyRose: Pigment(255, 228, 225, alpha: 1.0)
            case .moccasin: Pigment(255, 228, 181, alpha: 1.0)
            case .navajoWhite: Pigment(255, 222, 173, alpha: 1.0)
            case .navy: Pigment(0, 0, 128, alpha: 1.0)
            case .oldLace: Pigment(253, 245, 230, alpha: 1.0)
            case .olive: Pigment(128, 128, 0, alpha: 1.0)
            case .oliveDrab: Pigment(107, 142, 35, alpha: 1.0)
            case .orange: Pigment(255, 165, 0, alpha: 1.0)
            case .orangeRed: Pigment(255, 69, 0, alpha: 1.0)
            case .orchid: Pigment(218, 112, 214, alpha: 1.0)
            case .paleGoldenrod: Pigment(238, 232, 170, alpha: 1.0)
            case .paleGreen: Pigment(152, 251, 152, alpha: 1.0)
            case .paleTurquoise: Pigment(175, 238, 238, alpha: 1.0)
            case .paleVioletRed: Pigment(219, 112, 147, alpha: 1.0)
            case .papayaWhip: Pigment(255, 239, 213, alpha: 1.0)
            case .peachPuff: Pigment(255, 218, 185, alpha: 1.0)
            case .peru: Pigment(205, 133, 63, alpha: 1.0)
            case .pink: Pigment(255, 192, 203, alpha: 1.0)
            case .plum: Pigment(221, 160, 221, alpha: 1.0)
            case .powderBlue: Pigment(176, 224, 230, alpha: 1.0)
            case .purple: Pigment(128, 0, 128, alpha: 1.0)
            case .red: Pigment(255, 0, 0, alpha: 1.0)
            case .rosyBrown: Pigment(188, 143, 143, alpha: 1.0)
            case .royalBlue: Pigment(65, 105, 225, alpha: 1.0)
            case .saddleBrown: Pigment(139, 69, 19, alpha: 1.0)
            case .salmon: Pigment(250, 128, 114, alpha: 1.0)
            case .sandyBrown: Pigment(244, 164, 96, alpha: 1.0)
            case .seagreen: Pigment(46, 139, 87, alpha: 1.0)
            case .seashell: Pigment(255, 245, 238, alpha: 1.0)
            case .sienna: Pigment(160, 82, 45, alpha: 1.0)
            case .silver: Pigment(192, 192, 192, alpha: 1.0)
            case .skyBlue: Pigment(135, 206, 235, alpha: 1.0)
            case .slateBlue: Pigment(106, 90, 205, alpha: 1.0)
            case .slateGray: Pigment(112, 128, 144, alpha: 1.0)
            case .slateGrey: Pigment(112, 128, 144, alpha: 1.0)
            case .snow: Pigment(255, 250, 250, alpha: 1.0)
            case .springGreen: Pigment(0, 255, 127, alpha: 1.0)
            case .steelBlue: Pigment(70, 130, 180, alpha: 1.0)
            case .tan: Pigment(210, 180, 140, alpha: 1.0)
            case .teal: Pigment(0, 128, 128, alpha: 1.0)
            case .thistle: Pigment(216, 191, 216, alpha: 1.0)
            case .tomato: Pigment(255, 99, 71, alpha: 1.0)
            case .turquoise: Pigment(64, 224, 208, alpha: 1.0)
            case .violet: Pigment(238, 130, 238, alpha: 1.0)
            case .wheat: Pigment(245, 222, 179, alpha: 1.0)
            case .white: Pigment(255, 255, 255, alpha: 1.0)
            case .whitesmoke: Pigment(245, 245, 245, alpha: 1.0)
            case .yellow: Pigment(255, 255, 0, alpha: 1.0)
            case .yellowGreen: Pigment(154, 205, 50, alpha: 1.0)
            }
        }
    }

    init(
        _ name: Name,
        @Clamping(0 ... 1) alpha: Double = 1.0
    ) {
        red = Double(name.rgb.red) / 255.0
        green = Double(name.rgb.green) / 255.0
        blue = Double(name.rgb.blue) / 255.0
        self.alpha = alpha
    }
}
