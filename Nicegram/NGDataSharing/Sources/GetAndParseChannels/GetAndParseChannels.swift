import AccountContext
import FeatDataSharing
import NGCore
import NGUtils
import UIKit

public func getAndParseChannels(context: AccountContext) {
    Task { @MainActor in
        ChannelCollectorForegroundTrigger.shared.start(context: context)
    }
}

@MainActor
private final class ChannelCollectorForegroundTrigger {
    static let shared = ChannelCollectorForegroundTrigger()

    private weak var context: AccountContext?
    private var observer: NSObjectProtocol?

    func start(context: AccountContext) {
        self.context = context
        observeForeground()
        runChannelCollector(context: context)
    }

    private func observeForeground() {
        guard observer == nil else {
            return
        }
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.runForCurrentContext()
            }
        }
    }

    private func runForCurrentContext() {
        guard let context else {
            return
        }
        runChannelCollector(context: context)
    }
}

private func runChannelCollector(context: AccountContext) {
    // Nicegram Business, work-account data sharing: parse-channels
    guard !context.nicegramBusiness.restrictsAccountControl() else {
        return
    }
    //
    _ = Task {
        let getAndParseChannelsUseCase = DataSharingModule.shared.getAndParseChannelsUseCase()
        try await getAndParseChannelsUseCase(
            parse: { username, limits in
                await parseOutcome(
                    username,
                    context: context,
                    limits: limits
                )
            }
        )
    }
}

private func parseOutcome(
    _ username: String,
    context: AccountContext,
    limits: HistoryLimits
) async -> ChannelParseOutcome {
    do {
        let parser = ChannelParserFromApi(context: context)
        return .success(try await parser.parse(username, limits: limits))
    } catch let error as ChannelCollectorRpcError {
        return .fromRpcError(code: error.code, name: error.name)
    } catch is NotAChannelError {
        return .notAChannel
    } catch is ChannelUnavailableError {
        return .skip(.channelUnavailable)
    } catch let error as HistoryUnavailableError {
        return .skip(error.skipReason)
    } catch is TimeoutError {
        return .skip(.timeout)
    } catch {
        return .unexpected(error)
    }
}

private extension HistoryUnavailableError {
    var skipReason: ChannelParseOutcome.SkipReason {
        switch cause {
        case is TimeoutError:
            .timeout
        case let error as ChannelCollectorRpcError:
            .historyUnavailable(cause: "\(error.code) \(error.name)")
        default:
            .historyUnavailable(cause: String(describing: cause))
        }
    }
}
