import AccountContext
import Foundation
import NGCore
import TelegramApi
import TelegramBridge
import TelegramCore

public class ApiMediaFetcher {
    let context: AccountContext
    
    public init(context: AccountContext) {
        self.context = context
    }
}

public extension ApiMediaFetcher {
    func fetch(location: TelegramMediaApiLocation) async throws -> URL {
        let datacenterId: Int
        let inputFileLocation: Api.InputFileLocation
        switch location {
        case let .photo(photo):
            datacenterId = photo.datacenterId
            inputFileLocation = .inputPhotoFileLocation(
                id: photo.id,
                accessHash: photo.acessHash,
                fileReference: Buffer(data: photo.fileReference),
                thumbSize: photo.thumb_size
            )
        }
        
        return try await fetch(
            datacenterId: datacenterId,
            location: inputFileLocation
        )
    }
    
    func fetch(
        datacenterId: Int,
        location: Api.InputFileLocation
    ) async throws -> URL {
        let partSize = 128 * 1024

        let maxSize = 20 * 1024 * 1024

        let download = try await context.account.network
            .download(
                datacenterId: datacenterId,
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
                        location: location,
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
}
