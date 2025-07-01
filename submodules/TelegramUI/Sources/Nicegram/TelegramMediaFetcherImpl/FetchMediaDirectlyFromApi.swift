import Foundation
import NGCore
import TelegramApi
import TelegramBridge
import TelegramCore

func fetchMediaDirectlyFromApi(
    network: Network,
    location: TelegramMediaApiLocation
) async throws -> URL {
    switch location {
    case let .photo(photo):
        return try await fetchPhoto(
            network: network,
            location: photo
        )
    }
}

private func fetchPhoto(
    network: Network,
    location: TelegramMediaApiLocation.Photo
) async throws -> URL {
    let partSize = 128 * 1024

    let maxSize = 20 * 1024 * 1024

    let download = try await network
        .download(
            datacenterId: location.datacenterId,
            isMedia: false,
            tag: nil
        )
        .awaitForFirstValue()

    let tempUrl = URL.backportTemporaryDirectory
        .appendingPathComponent(UUID().uuidString)
    FileManager.default.createFile(atPath: tempUrl.path, contents: nil, attributes: nil)

    let fileHandle = try FileHandle(forWritingTo: tempUrl)
    defer { try? fileHandle.close() }

    var offset = 0
    while true {
        let file = try await download
            .request(
                Api.functions.upload.getFile(
                    flags: 0,
                    location: .inputPhotoFileLocation(
                        id: location.id,
                        accessHash: location.acessHash,
                        fileReference: Buffer(data: location.fileReference),
                        thumbSize: location.thumb_size
                    ),
                    offset: Int64(offset),
                    limit: Int32(partSize)
                )
            )
            .awaitForFirstValue()

        let data: Data
        switch file {
        case let .file(_, _, bytes):
            data = bytes.makeData()
        case .fileCdnRedirect:
            throw UnexpectedError()
        }

        if data.isEmpty {
            break
        }

        try fileHandle.seekToEnd()
        try fileHandle.write(contentsOf: data)

        offset += data.count

        if offset > maxSize {
            throw UnexpectedError()
        }

        if data.count < partSize {
            break
        }
    }

    return tempUrl
}
