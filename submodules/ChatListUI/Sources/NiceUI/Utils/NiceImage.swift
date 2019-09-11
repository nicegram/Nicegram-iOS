//
//  NiceImage.swift
//  TelegramUI
//
//  Created by Sergey Ak on 02/08/2019.
//  Copyright © 2019 Nicegram. All rights reserved.
//

import Foundation
import UIKit

public func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
}
