import Foundation

public enum AppError: Error, LocalizedError, Equatable, Sendable {
    case invalidInput(String)
    case unavailable(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidInput(message):
            message
        case let .unavailable(message):
            message
        case let .operationFailed(message):
            message
        }
    }
}
