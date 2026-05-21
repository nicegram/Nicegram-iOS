import UIKit
import Display
import ComponentFlow
import Speech
import AccountContext
import SwiftSignalKit
import ItemListUI
import TranslateUI
import TelegramPresentationData

import NGStrings
import NGUI

public enum RecognitionLanguagesControllerStyle {
    case normal, whisper
}

public func recognitionLanguagesController(
    context: AccountContext,
    style: RecognitionLanguagesControllerStyle = .normal,
    currentLocale: Locale?,
    selectLocale: @escaping (Locale) -> Void,
    selectWhisper: @escaping () -> Void,
    closeWithoutSelect: @escaping () -> Void
) -> ViewController {
    let languages = SFSpeechRecognizer.supportedLocales()
        .compactMap { locale -> LanguageInfo? in
            guard let title = locale.localizedString(forIdentifier: locale.identifier) else {
                return nil
            }
            let subtitle = locale.localizedString(forIdentifier: locale.identifier) ?? title
            
            return LanguageInfo(code: locale.identifier, title: title, subtitle: subtitle)
        }
        .sorted(by: { $0.title < $1.title })
    
    let initialState = LanguageListControllerState(
        languages: languages,
        selectedLanguageCode: currentLocale?.identifier
    )
    let statePromise = ValuePromise(initialState, ignoreRepeated: true)
    let stateValue = Atomic(value: initialState)
    let updateState: ((LanguageListControllerState) -> LanguageListControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    let arguments = LanguageListControllerArguments(
        selectLanguage: { code in
            updateState { state in
                var state = state
                state.selectedLanguageCode = code
                return state
            }
            selectLocale(Locale(identifier: code))
        },
        selectWhisper: {
            selectWhisper()
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> map { presentationData, state  -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(l("NicegramSpeechToText.Language.Title")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: .init(title: presentationData.strings.Common_Close)
        )

        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries(theme: presentationData.theme, state: state, style: style),
            style: .blocks,
            animateChanges: false
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.willDisappear = { _ in
        stateValue.with { state in
            if state.selectedLanguageCode == nil {
                closeWithoutSelect()
            }
        }
    }

    return controller
}

private func entries(
    theme: PresentationTheme,
    state: LanguageListControllerState,
    style: RecognitionLanguagesControllerStyle
) -> [RecognitionLanguageEntry] {
    var index: Int32 = 0
    var entries: [RecognitionLanguageEntry]
    
    if style == .whisper {
        let error = RecognitionLanguageEntry.whisper(
            index,
            theme,
            l("NicegramSpeechToText.Language.Whisper"),
            false
        )
        index += 1
        let header = RecognitionLanguageEntry.header(index, l("NicegramSpeechToText.Language.Choose").uppercased())
        entries = [error, header]
    } else {
        let header = RecognitionLanguageEntry.header(index, l("NicegramSpeechToText.Language.Choose").uppercased())
        entries = [header]
    }
    index += 1
    
    let (languages, selectedCode) = (state.languages, state.selectedLanguageCode)
    for lang in languages {
        entries.append(.language(index, theme, lang, lang.code == selectedCode))
        index += 1
    }
  
    return entries
}

private enum RecognitionLanguageSection: Int32 {
    case languages
    case whisper
    case header
}

private enum RecognitionLanguageEntry: ItemListNodeEntry {
    case header(Int32, String)
    case language(Int32, PresentationTheme, LanguageInfo, Bool)
    case whisper(Int32, PresentationTheme, String, Bool)
   
    var section: ItemListSectionId {
        switch self {
        case .language:
            return RecognitionLanguageSection.languages.rawValue
        case .whisper:
            return RecognitionLanguageSection.whisper.rawValue
        case .header:
            return RecognitionLanguageSection.languages.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .language(index, _, _, _): return index
        case let .whisper(index, _, _, _): return index
        case let .header(index, _): return index
        }
    }
    
    static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! LanguageListControllerArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
        case let .whisper(_, _, message, _):
            return ItemListTextWithBackgroundItem(
                presentationData: presentationData,
                text: .markdown(message),
                style: .blocks,
                sectionId: self.section,
                linkAction: { _ in
                    arguments.selectWhisper()
                }
            )
        case let .language(_, _, info, value):
            return LocalizationListItem(
                presentationData: presentationData,
                id: info.code,
                title: info.title,
                subtitle: info.subtitle,
                checked: value,
                activity: false,
                loading: false,
                editing: LocalizationListItemEditing(
                    editable: false,
                    editing: false,
                    revealed: false,
                    reorderable: false
                ),
                sectionId: self.section,
                alwaysPlain: false,
                action: {
                    if !value {
                        arguments.selectLanguage(info.code)
                    }
                },
                setItemWithRevealedOptions: { _, _ in },
                removeItem: { _ in }
            )
        }
    }
}
