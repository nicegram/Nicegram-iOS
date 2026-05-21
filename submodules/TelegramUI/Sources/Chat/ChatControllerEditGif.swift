import Foundation
import UIKit
import SwiftSignalKit
import TelegramCore
import AsyncDisplayKit
import Display
import AccountContext
import ChatControllerInteraction
import LegacyMediaPickerUI

extension ChatControllerImpl {
    func openGifEditing(file: FileMediaReference, addCaption: Bool) {
        guard let peer = self.presentationInterfaceState.renderedPeer?.peer else {
            return
        }
        let hasSilentPosting = peer.id != self.context.account.peerId
        let hasSchedule = self.presentationInterfaceState.subject != .scheduledMessages && peer.id.namespace != Namespaces.Peer.SecretChat && self.presentationInterfaceState.sendPaidMessageStars == nil
        legacyMediaEditor(
            context: self.context,
            peer: peer,
            threadTitle: nil,
            media: file.abstract,
            mode: addCaption ? .caption : .default,
            initialCaption: NSAttributedString(),
            snapshots: [],
            transitionCompletion: {
            },
            getCaptionPanelView: { [weak self] in
                return self?.getCaptionPanelView(isFile: false, hasTimer: false)
            },
            hasSilentPosting: hasSilentPosting,
            hasSchedule: hasSchedule,
            reminder: peer.id == self.context.account.peerId,
            presentSchedulePicker: { [weak self] _, done in
                guard let self else {
                    return
                }
                self.presentScheduleTimePicker(style: .media, completion: { [weak self] result in
                    guard let self else {
                        return
                    }
                    done(result.time, result.silentPosting)
                    if self.presentationInterfaceState.subject != .scheduledMessages && result.time != scheduleWhenOnlineTimestamp {
                        self.openScheduledMessages()
                    }
                })
            },
            sendMessagesWithSignals: { [weak self] signals, silentPosting, scheduleTime, isCaptionAbove in
                guard let self else {
                    return
                }
                let parameters = ChatSendMessageActionSheetController.SendParameters(
                    effect: nil,
                    textIsAboveMedia: isCaptionAbove
                )
                self.enqueueMediaMessages(
                    fromGallery: false,
                    signals: signals,
                    originalMediaReference: file.abstract,
                    silentPosting: silentPosting,
                    scheduleTime: scheduleTime == 0 ? nil : scheduleTime,
                    replyToSubject: nil,
                    parameters: parameters,
                    getAnimatedTransitionSource: nil,
                    completion: {}
                )
            },
            present: { [weak self] c, a in
                c.navigationPresentation = .flatModal
                self?.push(c)
            }
        )
    }
}
