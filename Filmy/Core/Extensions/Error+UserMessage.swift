import Foundation
import NetworkingKit

extension Error {
    /// A message worth showing, or nil when the error is a cancellation (the screen moved on).
    var userMessage: String? {
        switch self {
        case is CancellationError, NetworkError.cancelled:
            nil
        case let error as NetworkError:
            error.errorDescription
        default:
            localizedDescription
        }
    }
}
