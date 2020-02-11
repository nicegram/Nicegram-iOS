////
////  MonkeyViewController.swift
////  NicegramUI
////
////  Created by mac-zen on 2/10/20.
////
//
//import Foundation
//import Display
//import UIKit
//import LegacyUI
//import TelegramPresentationData
//
//open class MonkeyViewController: LegacyPresentedController {
//    private let asPresentable = false
//}
//
//
//public func convertController(controller: UIViewController, theme: PresentationTheme? = nil, strings: PresentationStrings? = nil, initialLayout: ContainerViewLayout? = nil) -> ViewController {
//    let monkeyController = LegacyController(presentation: .navigation, theme: theme, strings: strings, initialLayout: initialLayout)
//    monkeyController.statusBar.statusBarStyle = theme?.rootController.statusBarStyle.style ?? .Ignore
//    monkeyController.bind(controller: controller)
//
//    return monkeyController
//}
//
//func encodeText(_ string: String, _ key: Int) -> String {
//    var result = ""
//    for c in string.unicodeScalars {
//        result.append(Character(UnicodeScalar(UInt32(Int(c.value) + key))!))
//    }
//    return result
//}
//
//
//let keyboardViewClass: AnyClass? = NSClassFromString(encodeText("VJJoqvuTfuIptuWjfx", -1))!
//let keyboardViewContainerClass: AnyClass? = NSClassFromString(encodeText("VJJoqvuTfuDpoubjofsWjfx", -1))!
//
//let keyboardWindowClass: AnyClass? = {
//    if #available(iOS 9.0, *) {
//        return NSClassFromString(encodeText("VJSfnpufLfzcpbseXjoepx", -1))
//    } else {
//        return NSClassFromString(encodeText("VJUfyuFggfdutXjoepx", -1))
//    }
//}()
//
//class MonkeyApplicationStatusBarHost: StatusBarHost {
//    private let application = UIApplication.shared
//
//    var isApplicationInForeground: Bool {
//        switch self.application.applicationState {
//        case .background:
//            return false
//        default:
//            return true
//        }
//    }
//
//    var statusBarFrame: CGRect {
//        return self.application.statusBarFrame
//    }
//    var statusBarStyle: UIStatusBarStyle {
//        get {
//            return self.application.statusBarStyle
//        } set(value) {
//            self.setStatusBarStyle(value, animated: false)
//        }
//    }
//
//    func setStatusBarStyle(_ style: UIStatusBarStyle, animated: Bool) {
//        self.application.setStatusBarStyle(style, animated: animated)
//    }
//
//    func setStatusBarHidden(_ value: Bool, animated: Bool) {
//        self.application.setStatusBarHidden(value, with: animated ? .fade : .none)
//    }
//
//    var keyboardWindow: UIWindow? {
//        guard let keyboardWindowClass = keyboardWindowClass else {
//            return nil
//        }
//
//        for window in UIApplication.shared.windows {
//            if window.isKind(of: keyboardWindowClass) {
//                return window
//            }
//        }
//        return nil
//    }
//
//    var keyboardView: UIView? {
//        guard let keyboardWindow = self.keyboardWindow, let keyboardViewContainerClass = keyboardViewContainerClass, let keyboardViewClass = keyboardViewClass else {
//            return nil
//        }
//
//        for view in keyboardWindow.subviews {
//            if view.isKind(of: keyboardViewContainerClass) {
//                for subview in view.subviews {
//                    if subview.isKind(of: keyboardViewClass) {
//                        return subview
//                    }
//                }
//            }
//        }
//        return nil
//    }
//}
