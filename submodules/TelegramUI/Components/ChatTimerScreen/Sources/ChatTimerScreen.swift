import Foundation
import UIKit
import Display
import TelegramCore
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import PresentationDataUtils
import TelegramStringFormatting
import ComponentFlow
import ViewControllerComponent
import SheetComponent
import ButtonComponent
import BundleIconComponent
import GlassBarButtonComponent

public enum ChatTimerScreenStyle {
    case `default`
    case media
}

public enum ChatTimerScreenMode {
    case sendTimer
    case autoremove
    case mute
}

private protocol TimerPickerView: UIView {
}

private class TimerCustomPickerView: UIPickerView, TimerPickerView {
    var selectorColor: UIColor? = nil {
        didSet {
            for subview in self.subviews {
                if subview.bounds.height <= 1.0 {
                    subview.backgroundColor = self.selectorColor
                }
            }
        }
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if let selectorColor = self.selectorColor {
            if subview.bounds.height <= 1.0 {
                subview.backgroundColor = selectorColor
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if let selectorColor = self.selectorColor {
            for subview in self.subviews {
                if subview.bounds.height <= 1.0 {
                    subview.backgroundColor = selectorColor
                }
            }
        }
    }
}

private class TimerDatePickerView: UIDatePicker, TimerPickerView {
    var selectorColor: UIColor? = nil {
        didSet {
            for subview in self.subviews {
                if subview.bounds.height <= 1.0 {
                    subview.backgroundColor = self.selectorColor
                }
            }
        }
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if let selectorColor = self.selectorColor {
            if subview.bounds.height <= 1.0 {
                subview.backgroundColor = selectorColor
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if let selectorColor = self.selectorColor {
            for subview in self.subviews {
                if subview.bounds.height <= 1.0 {
                    subview.backgroundColor = selectorColor
                }
            }
        }
    }
}

private let digitsCharacterSet = CharacterSet(charactersIn: "0123456789")
private let nondigitsCharacterSet = CharacterSet(charactersIn: "0123456789").inverted

private class TimerPickerItemView: UIView {
    let valueLabel = UILabel()
    let unitLabel = UILabel()

    var textColor: UIColor? = nil {
        didSet {
            self.valueLabel.textColor = self.textColor
            self.unitLabel.textColor = self.textColor
        }
    }

    var value: (Int32, String)? {
        didSet {
            if let (value, string) = self.value {
                let components = string.components(separatedBy: " ")
                if value == viewOnceTimeout {
                    self.valueLabel.text = string
                    self.unitLabel.text = ""
                } else if components.count > 1 {
                    self.valueLabel.text = components[0]
                    self.unitLabel.text = components[1]
                } else {
                    self.valueLabel.text = string.trimmingCharacters(in: nondigitsCharacterSet)
                    self.unitLabel.text = string.trimmingCharacters(in: digitsCharacterSet)
                }
            }

            self.setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        self.valueLabel.backgroundColor = nil
        self.valueLabel.isOpaque = false
        self.valueLabel.font = Font.regular(24.0)

        self.unitLabel.backgroundColor = nil
        self.unitLabel.isOpaque = false
        self.unitLabel.font = Font.medium(16.0)

        super.init(frame: frame)

        self.addSubview(self.valueLabel)
        self.addSubview(self.unitLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.valueLabel.sizeToFit()
        self.unitLabel.sizeToFit()

        if let (value, _) = self.value, value == viewOnceTimeout {
            self.valueLabel.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((self.frame.width - self.valueLabel.frame.size.width) / 2.0), y: floor((self.frame.height - self.valueLabel.frame.height) / 2.0)), size: self.valueLabel.frame.size)
        } else {
            self.valueLabel.frame = CGRect(origin: CGPoint(x: self.frame.width / 2.0 - 28.0 - self.valueLabel.frame.size.width, y: floor((self.frame.height - self.valueLabel.frame.height) / 2.0)), size: self.valueLabel.frame.size)
            self.unitLabel.frame = CGRect(origin: CGPoint(x: self.frame.width / 2.0 - 20.0, y: floor((self.frame.height - self.unitLabel.frame.height) / 2.0) + 2.0), size: self.unitLabel.frame.size)
        }
    }
}

private var timerValues: [Int32] = {
    var values: [Int32] = []
    for i in 1 ..< 20 {
        values.append(Int32(i))
    }
    for i in 0 ..< 9 {
        values.append(Int32(20 + i * 5))
    }
    return values
}()

private let autoremoveTimerValues: [Int32] = [
    1 * 24 * 60 * 60 as Int32,
    2 * 24 * 60 * 60 as Int32,
    3 * 24 * 60 * 60 as Int32,
    4 * 24 * 60 * 60 as Int32,
    5 * 24 * 60 * 60 as Int32,
    6 * 24 * 60 * 60 as Int32,
    1 * 7 * 24 * 60 * 60 as Int32,
    2 * 7 * 24 * 60 * 60 as Int32,
    3 * 7 * 24 * 60 * 60 as Int32,
    1 * 31 * 24 * 60 * 60 as Int32,
    2 * 30 * 24 * 60 * 60 as Int32,
    3 * 31 * 24 * 60 * 60 as Int32,
    4 * 30 * 24 * 60 * 60 as Int32,
    5 * 31 * 24 * 60 * 60 as Int32,
    6 * 30 * 24 * 60 * 60 as Int32,
    365 * 24 * 60 * 60 as Int32
]

private final class ChatTimerSheetContentComponent: Component {
    typealias EnvironmentType = ViewControllerComponentContainer.Environment

    let style: ChatTimerScreenStyle
    let mode: ChatTimerScreenMode
    let currentTime: Int32?
    let dismiss: () -> Void

    init(
        style: ChatTimerScreenStyle,
        mode: ChatTimerScreenMode,
        currentTime: Int32?,
        dismiss: @escaping () -> Void
    ) {
        self.style = style
        self.mode = mode
        self.currentTime = currentTime
        self.dismiss = dismiss
    }

    static func ==(lhs: ChatTimerSheetContentComponent, rhs: ChatTimerSheetContentComponent) -> Bool {
        if lhs.style != rhs.style {
            return false
        }
        if lhs.mode != rhs.mode {
            return false
        }
        if lhs.currentTime != rhs.currentTime {
            return false
        }
        return true
    }

    final class View: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
        private let closeButton = ComponentView<Empty>()
        private let title = ComponentView<Empty>()
        private let primaryButton = ComponentView<Empty>()
        private let secondaryButton = ComponentView<Empty>()

        private var component: ChatTimerSheetContentComponent?
        private var environment: EnvironmentType?
        private weak var state: EmptyComponentState?

        private var pickerView: TimerPickerView?
        private var isCompleting = false

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func selectedValue() -> Int32? {
            guard let component = self.component, let pickerView = self.pickerView else {
                return nil
            }

            if let pickerView = pickerView as? TimerCustomPickerView {
                switch component.mode {
                case .sendTimer:
                    let row = pickerView.selectedRow(inComponent: 0)
                    if row == 0 {
                        return viewOnceTimeout
                    } else {
                        return timerValues[row - 1]
                    }
                case .autoremove:
                    return autoremoveTimerValues[pickerView.selectedRow(inComponent: 0)]
                case .mute:
                    return nil
                }
            } else if let pickerView = pickerView as? TimerDatePickerView {
                return Int32(pickerView.date.timeIntervalSince1970)
            } else {
                return nil
            }
        }

        private func pickerTextColor(component: ChatTimerSheetContentComponent, environment: EnvironmentType) -> UIColor {
            switch component.mode {
            case .sendTimer:
                return .white
            case .autoremove:
                if case .media = component.style {
                    return .white
                } else {
                    return environment.theme.list.itemPrimaryTextColor
                }
            case .mute:
                if case .media = component.style {
                    return .white
                } else {
                    return environment.theme.list.itemPrimaryTextColor
                }
            }
        }

        private func selectAutoremoveValue(_ value: Int32, in pickerView: TimerCustomPickerView) {
            var selectedRowIndex = 0
            for i in 0 ..< autoremoveTimerValues.count {
                if autoremoveTimerValues[i] <= value {
                    selectedRowIndex = i
                }
            }
            pickerView.selectRow(selectedRowIndex, inComponent: 0, animated: false)
        }

        private func setupPickerView(component: ChatTimerSheetContentComponent, environment: EnvironmentType) {
            let previousSelectedValue = self.selectedValue()
            let previousDate = (self.pickerView as? TimerDatePickerView)?.date

            if let pickerView = self.pickerView {
                pickerView.removeFromSuperview()
            }

            switch component.mode {
            case .sendTimer:
                let pickerView = TimerCustomPickerView()
                pickerView.selectorColor = UIColor(rgb: 0xffffff, alpha: 0.18)
                pickerView.dataSource = self
                pickerView.delegate = self
                self.addSubview(pickerView)
                self.pickerView = pickerView

                if let previousSelectedValue {
                    if previousSelectedValue == viewOnceTimeout {
                        pickerView.selectRow(0, inComponent: 0, animated: false)
                    } else if let index = timerValues.firstIndex(of: previousSelectedValue) {
                        pickerView.selectRow(index + 1, inComponent: 0, animated: false)
                    }
                }
            case .autoremove:
                let pickerView = TimerCustomPickerView()
                pickerView.dataSource = self
                pickerView.delegate = self
                pickerView.selectorColor = self.pickerTextColor(component: component, environment: environment).withMultipliedAlpha(0.18)
                self.addSubview(pickerView)
                self.pickerView = pickerView

                if let previousSelectedValue {
                    self.selectAutoremoveValue(previousSelectedValue, in: pickerView)
                } else if let currentTime = component.currentTime {
                    self.selectAutoremoveValue(currentTime, in: pickerView)
                }
            case .mute:
                let pickerView = TimerDatePickerView()
                pickerView.locale = localeWithStrings(environment.strings)
                pickerView.datePickerMode = .dateAndTime
                pickerView.minimumDate = Date()
                if #available(iOS 13.4, *) {
                    pickerView.preferredDatePickerStyle = .wheels
                }
                pickerView.setValue(self.pickerTextColor(component: component, environment: environment), forKey: "textColor")
                pickerView.setValue(false, forKey: "highlightsToday")
                pickerView.selectorColor = UIColor(rgb: 0xffffff, alpha: 0.18)
                pickerView.addTarget(self, action: #selector(self.datePickerChanged), for: .valueChanged)
                if let previousDate {
                    pickerView.date = max(previousDate, Date())
                }
                self.addSubview(pickerView)
                self.pickerView = pickerView
            }
        }

        @objc private func datePickerChanged() {
            self.state?.updated(transition: .immediate)
        }

        private func title(strings: PresentationStrings) -> String {
            guard let component = self.component else {
                return ""
            }

            switch component.mode {
            case .sendTimer:
                return strings.Conversation_Timer_Title
            case .autoremove:
                return strings.Conversation_DeleteTimer_SetupTitle
            case .mute:
                return strings.Conversation_Mute_SetupTitle
            }
        }

        private func primaryButtonTitle(component: ChatTimerSheetContentComponent, environment: EnvironmentType) -> String {
            switch component.mode {
            case .sendTimer:
                return environment.strings.Conversation_Timer_Send
            case .autoremove:
                return environment.strings.Conversation_DeleteTimer_Apply
            case .mute:
                if let pickerView = self.pickerView as? TimerDatePickerView {
                    let now = Int32(Date().timeIntervalSince1970)
                    let timeInterval = max(0, Int32(pickerView.date.timeIntervalSince1970) - now)

                    if timeInterval > 0 {
                        let timeString = stringForPreciseRelativeTimestamp(strings: environment.strings, relativeTimestamp: Int32(pickerView.date.timeIntervalSince1970), relativeTo: now, dateTimeFormat: environment.dateTimeFormat)
                        return environment.strings.Conversation_Mute_ApplyMuteUntil(timeString).string
                    } else {
                        return environment.strings.Common_Close
                    }
                } else {
                    return environment.strings.Common_Close
                }
            }
        }

        private func complete(value: Int32) {
            guard !self.isCompleting else {
                return
            }
            self.isCompleting = true

            if let controller = self.environment?.controller() as? ChatTimerScreen {
                controller.completion(value)
            }
            self.component?.dismiss()
        }

        private func completeWithPickerValue() {
            guard let component = self.component, let pickerView = self.pickerView else {
                return
            }

            if let pickerView = pickerView as? TimerCustomPickerView {
                switch component.mode {
                case .sendTimer:
                    let row = pickerView.selectedRow(inComponent: 0)
                    let value: Int32
                    if row == 0 {
                        value = viewOnceTimeout
                    } else {
                        value = timerValues[row - 1]
                    }
                    self.complete(value: value)
                case .autoremove:
                    self.complete(value: autoremoveTimerValues[pickerView.selectedRow(inComponent: 0)])
                case .mute:
                    break
                }
            } else if let pickerView = pickerView as? TimerDatePickerView {
                switch component.mode {
                case .mute:
                    let timeInterval = max(0, Int32(pickerView.date.timeIntervalSince1970) - Int32(Date().timeIntervalSince1970))
                    self.complete(value: timeInterval)
                default:
                    break
                }
            }
        }

        func update(component: ChatTimerSheetContentComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
            let environment = environment[EnvironmentType.self].value
            let previousComponent = self.component
            let previousEnvironment = self.environment
            let themeUpdated: Bool
            let stringsUpdated: Bool
            if let previousEnvironment {
                themeUpdated = previousEnvironment.theme !== environment.theme
                stringsUpdated = previousEnvironment.strings !== environment.strings
            } else {
                themeUpdated = false
                stringsUpdated = false
            }

            self.component = component
            self.environment = environment
            self.state = state

            if self.pickerView == nil || previousComponent?.mode != component.mode || previousComponent?.style != component.style || themeUpdated || stringsUpdated {
                self.setupPickerView(component: component, environment: environment)
            }

            let titleColor: UIColor
            switch component.style {
            case .default:
                titleColor = environment.theme.actionSheet.primaryTextColor
            case .media:
                titleColor = .white
            }

            let barButtonSize = CGSize(width: 44.0, height: 44.0)
            let closeButtonSize = self.closeButton.update(
                transition: transition,
                component: AnyComponent(
                    GlassBarButtonComponent(
                        size: barButtonSize,
                        backgroundColor: nil,
                        isDark: environment.theme.overallDarkAppearance,
                        state: .glass,
                        component: AnyComponentWithIdentity(id: "close", component: AnyComponent(
                            BundleIconComponent(
                                name: "Navigation/Close",
                                tintColor: environment.theme.chat.inputPanel.panelControlColor
                            )
                        )),
                        action: { [weak self] _ in
                            self?.component?.dismiss()
                        }
                    )
                ),
                environment: {},
                containerSize: barButtonSize
            )
            if let closeButtonView = self.closeButton.view {
                if closeButtonView.superview == nil {
                    self.addSubview(closeButtonView)
                }
                transition.setFrame(view: closeButtonView, frame: CGRect(origin: CGPoint(x: 16.0, y: 16.0), size: closeButtonSize))
            }

            let titleSize = self.title.update(
                transition: transition,
                component: AnyComponent(
                    Text(text: self.title(strings: environment.strings), font: Font.semibold(17.0), color: titleColor)
                ),
                environment: {},
                containerSize: CGSize(width: availableSize.width - 120.0, height: 44.0)
            )
            if let titleView = self.title.view {
                if titleView.superview == nil {
                    self.addSubview(titleView)
                }
                transition.setFrame(view: titleView, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((availableSize.width - titleSize.width) / 2.0), y: floorToScreenPixels(16.0 + (barButtonSize.height - titleSize.height) / 2.0)), size: titleSize))
            }

            var contentHeight: CGFloat = 68.0

            let pickerHeight: CGFloat = 216.0
            if let pickerView = self.pickerView {
                transition.setFrame(view: pickerView as UIView, frame: CGRect(origin: CGPoint(x: 0.0, y: contentHeight), size: CGSize(width: availableSize.width, height: pickerHeight)))
            }
            contentHeight += pickerHeight
            contentHeight += 17.0

            let buttonSideInset: CGFloat = 30.0
            let primaryButtonTitle = self.primaryButtonTitle(component: component, environment: environment)
            let primaryButtonSize = self.primaryButton.update(
                transition: transition,
                component: AnyComponent(ButtonComponent(
                    background: ButtonComponent.Background(
                        style: .glass,
                        color: environment.theme.list.itemCheckColors.fillColor,
                        foreground: environment.theme.list.itemCheckColors.foregroundColor,
                        pressedColor: environment.theme.list.itemCheckColors.fillColor.withMultipliedAlpha(0.8)
                    ),
                    content: AnyComponentWithIdentity(id: AnyHashable(primaryButtonTitle), component: AnyComponent(
                        Text(text: primaryButtonTitle, font: Font.semibold(17.0), color: environment.theme.list.itemCheckColors.foregroundColor)
                    )),
                    isEnabled: true,
                    displaysProgress: false,
                    action: { [weak self] in
                        self?.completeWithPickerValue()
                    }
                )),
                environment: {},
                containerSize: CGSize(width: availableSize.width - buttonSideInset * 2.0, height: 52.0)
            )
            if let primaryButtonView = self.primaryButton.view {
                if primaryButtonView.superview == nil {
                    self.addSubview(primaryButtonView)
                }
                transition.setFrame(view: primaryButtonView, frame: CGRect(origin: CGPoint(x: buttonSideInset, y: contentHeight), size: primaryButtonSize))
            }
            contentHeight += primaryButtonSize.height

            if case .autoremove = component.mode, component.currentTime != nil {
                contentHeight += 8.0

                let secondaryButtonTitle = environment.strings.Conversation_DeleteTimer_Disable
                let secondaryButtonSize = self.secondaryButton.update(
                    transition: transition,
                    component: AnyComponent(ButtonComponent(
                        background: ButtonComponent.Background(
                            style: .glass,
                            color: environment.theme.list.itemDestructiveColor.withMultipliedAlpha(0.1),
                            foreground: environment.theme.list.itemDestructiveColor,
                            pressedColor: environment.theme.list.itemDestructiveColor.withMultipliedAlpha(0.8)
                        ),
                        content: AnyComponentWithIdentity(id: AnyHashable(secondaryButtonTitle), component: AnyComponent(
                            Text(text: secondaryButtonTitle, font: Font.semibold(17.0), color: environment.theme.list.itemDestructiveColor)
                        )),
                        isEnabled: true,
                        displaysProgress: false,
                        action: { [weak self] in
                            self?.complete(value: 0)
                        }
                    )),
                    environment: {},
                    containerSize: CGSize(width: availableSize.width - buttonSideInset * 2.0, height: 52.0)
                )
                if let secondaryButtonView = self.secondaryButton.view {
                    if secondaryButtonView.superview == nil {
                        self.addSubview(secondaryButtonView)
                    }
                    transition.setFrame(view: secondaryButtonView, frame: CGRect(origin: CGPoint(x: buttonSideInset, y: contentHeight), size: secondaryButtonSize))
                }
                contentHeight += secondaryButtonSize.height
            } else if let secondaryButtonView = self.secondaryButton.view, secondaryButtonView.superview != nil {
                secondaryButtonView.removeFromSuperview()
            }

            let bottomInset: CGFloat = environment.safeInsets.bottom > 0.0 ? environment.safeInsets.bottom + 5.0 : 15.0
            contentHeight += bottomInset

            return CGSize(width: availableSize.width, height: contentHeight)
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            guard let component = self.component else {
                return 0
            }

            switch component.mode {
            case .sendTimer:
                return timerValues.count + 1
            case .autoremove:
                return autoremoveTimerValues.count
            case .mute:
                return 0
            }
        }

        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent componentIndex: Int, reusing view: UIView?) -> UIView {
            guard let component = self.component, let environment = self.environment else {
                return UIView()
            }

            let itemView: TimerPickerItemView
            if let current = view as? TimerPickerItemView {
                itemView = current
            } else {
                itemView = TimerPickerItemView()
            }
            itemView.textColor = self.pickerTextColor(component: component, environment: environment)

            switch component.mode {
            case .sendTimer:
                if row == 0 {
                    let string = environment.strings.MediaPicker_Timer_ViewOnce
                    itemView.value = (viewOnceTimeout, string)
                } else {
                    let value = timerValues[row - 1]
                    let string = timeIntervalString(strings: environment.strings, value: value)
                    itemView.value = (value, string)
                }
            case .autoremove:
                let value = autoremoveTimerValues[row]
                let string = timeIntervalString(strings: environment.strings, value: value)
                itemView.value = (value, string)
            case .mute:
                preconditionFailure()
            }

            return itemView
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.state?.updated(transition: .immediate)
        }
    }

    func makeView() -> View {
        return View(frame: CGRect())
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<EnvironmentType>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

private final class ChatTimerSheetComponent: Component {
    typealias EnvironmentType = ViewControllerComponentContainer.Environment

    let style: ChatTimerScreenStyle
    let mode: ChatTimerScreenMode
    let currentTime: Int32?

    init(
        style: ChatTimerScreenStyle,
        mode: ChatTimerScreenMode,
        currentTime: Int32?
    ) {
        self.style = style
        self.mode = mode
        self.currentTime = currentTime
    }

    static func ==(lhs: ChatTimerSheetComponent, rhs: ChatTimerSheetComponent) -> Bool {
        if lhs.style != rhs.style {
            return false
        }
        if lhs.mode != rhs.mode {
            return false
        }
        if lhs.currentTime != rhs.currentTime {
            return false
        }
        return true
    }

    final class View: UIView {
        private let sheet = ComponentView<(ViewControllerComponentContainer.Environment, SheetComponentEnvironment)>()
        private let sheetAnimateOut = ActionSlot<Action<Void>>()

        private var component: ChatTimerSheetComponent?
        private var environment: EnvironmentType?

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func dismiss() {
            self.sheetAnimateOut.invoke(Action { [weak self] _ in
                guard let self, let controller = self.environment?.controller() else {
                    return
                }
                controller.dismiss(completion: nil)
            })
        }

        func update(component: ChatTimerSheetComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<ViewControllerComponentContainer.Environment>, transition: ComponentTransition) -> CGSize {
            self.component = component

            let environment = environment[ViewControllerComponentContainer.Environment.self].value
            self.environment = environment

            let sheetEnvironment = SheetComponentEnvironment(
                metrics: environment.metrics,
                deviceMetrics: environment.deviceMetrics,
                isDisplaying: environment.isVisible,
                isCentered: environment.metrics.widthClass == .regular,
                hasInputHeight: !environment.inputHeight.isZero,
                regularMetricsSize: CGSize(width: 430.0, height: 900.0),
                dismiss: { [weak self] _ in
                    self?.dismiss()
                }
            )

            let backgroundColor: UIColor
            switch component.style {
            case .default:
                backgroundColor = environment.theme.actionSheet.opaqueItemBackgroundColor
            case .media:
                backgroundColor = UIColor(rgb: 0x1c1c1e)
            }

            let _ = self.sheet.update(
                transition: transition,
                component: AnyComponent(SheetComponent(
                    content: AnyComponent(ChatTimerSheetContentComponent(
                        style: component.style,
                        mode: component.mode,
                        currentTime: component.currentTime,
                        dismiss: { [weak self] in
                            self?.dismiss()
                        }
                    )),
                    style: .glass,
                    backgroundColor: .color(backgroundColor),
                    followContentSizeChanges: true,
                    animateOut: self.sheetAnimateOut
                )),
                environment: {
                    environment
                    sheetEnvironment
                },
                containerSize: availableSize
            )
            if let sheetView = self.sheet.view {
                if sheetView.superview == nil {
                    self.addSubview(sheetView)
                }
                transition.setFrame(view: sheetView, frame: CGRect(origin: CGPoint(), size: availableSize))
            }

            return availableSize
        }
    }

    func makeView() -> View {
        return View(frame: CGRect())
    }

    func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<ViewControllerComponentContainer.Environment>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}

public final class ChatTimerScreen: ViewControllerComponentContainer {
    fileprivate let completion: (Int32) -> Void

    public init(
        context: AccountContext,
        updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil,
        style: ChatTimerScreenStyle,
        mode: ChatTimerScreenMode = .sendTimer,
        currentTime: Int32? = nil,
        completion: @escaping (Int32) -> Void
    ) {
        self.completion = completion

        super.init(
            context: context,
            component: ChatTimerSheetComponent(
                style: style,
                mode: mode,
                currentTime: currentTime
            ),
            navigationBarAppearance: .none,
            statusBarStyle: .ignore,
            theme: style == .media ? .dark : .default,
            updatedPresentationData: updatedPresentationData
        )

        self.statusBar.statusBarStyle = .Ignore
        self.navigationPresentation = .flatModal
        self.blocksBackgroundWhenInOverlay = true
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.view.disablesInteractiveModalDismiss = true
    }

    public func dismissAnimated() {
        if let view = self.node.hostView.findTaggedView(tag: SheetComponent<ViewControllerComponentContainer.Environment>.View.Tag()) as? SheetComponent<ViewControllerComponentContainer.Environment>.View {
            view.dismissAnimated()
        }
    }
}
