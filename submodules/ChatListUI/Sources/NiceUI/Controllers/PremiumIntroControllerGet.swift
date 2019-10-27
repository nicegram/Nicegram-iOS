//
//  PremiumIntroControllerGet.swift
//  ChatListUI
//
//  Created by Sergey on 27.10.2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import TelegramPermissionsUI
import TelegramPermissions
import TelegramPresentationData
import AccountContext
import Display
import UIKit
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore



public func getPremiumIntroController(context: AccountContext, presentationData: PresentationData) -> PremiumIntroController {
    
    let controller = PremiumIntroController(context: context, splashScreen: true)
    controller.setState(.custom(icon: PremiumIntroControllerCustomIcon(light: UIImage(bundleImageName: "Chat/Intro/PremiumIntro"), dark: nil), title: "Premium", subtitle: "Unique features you can't refuse!", text: "Unlimited folders\nUnlimited pinned chats\nMissed messages notification (Digest)", buttonTitle: "Pay $0.00", footerText: nil), animated: true)
    return controller
}
