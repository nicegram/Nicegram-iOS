import AccountContext
import TelegramCore
import UIKit

public func shareController(
    image: UIImage?,
    text: String,
    context: AccountContext
) async -> ShareController {
    let media = try? await prepareImage(image: image, context: context)
    
    let subject: ShareControllerSubject
    if let media {
        subject = .media(media, nil, text: text)
    } else {
        subject = .text(text)
    }
    
    return await ShareController(
        context: context,
        subject: subject
    )
}

private func prepareImage(
    image: UIImage?,
    context: AccountContext
) async throws -> AnyMediaReference? {
    guard let image else {
        return nil
    }

    let account = context.account
    let postbox = account.postbox
    let network = account.network
    let peerId = account.peerId

    // Copied from
    // https://bitbucket.org/mobyrix/nicegram-ios/src/develop/submodules/ShareItems/Sources/ShareItems.swift
    let nativeImageSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    let dimensions = nativeImageSize.fitted(CGSize(width: 1280.0, height: 1280.0))
    if let scaledImage = scalePhotoImage(image, dimensions: dimensions),
       let imageData = scaledImage.jpegData(compressionQuality: 0.52) {
        let stream = standaloneUploadedImage(postbox: postbox, network: network, peerId: peerId, text: "", data: imageData, dimensions: PixelDimensions(dimensions)).asyncStream(.bufferingNewest(1))
        for try await event in stream {
            if case let .result(result) = event,
               case let .media(media) = result {
                return media
            }
        }
    }
    
    return nil
}

private func scalePhotoImage(_ image: UIImage, dimensions: CGSize) -> UIImage? {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    let renderer = UIGraphicsImageRenderer(size: dimensions, format: format)
    return renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: dimensions))
    }
}
