import Foundation

#if canImport(OSLog)
import OSLog
#endif

public struct AppLogger {
    private let category: String

    #if canImport(OSLog)
    private let logger: Logger
    #endif

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "MarquisAppleKit",
        category: String
    ) {
        self.category = category

        #if canImport(OSLog)
        logger = Logger(subsystem: subsystem, category: category)
        #endif
    }

    public func debug(_ message: @autoclosure () -> String) {
        log(level: "DEBUG", message: message())
    }

    public func info(_ message: @autoclosure () -> String) {
        log(level: "INFO", message: message())
    }

    public func error(_ message: @autoclosure () -> String) {
        let text = message()

        #if canImport(OSLog)
        logger.error("\(text, privacy: .public)")
        #else
        print("[ERROR][\(category)] \(text)")
        #endif
    }

    private func log(level: String, message: String) {
        #if canImport(OSLog)
        if level == "DEBUG" {
            logger.debug("\(message, privacy: .public)")
        } else {
            logger.info("\(message, privacy: .public)")
        }
        #else
        print("[\(level)][\(category)] \(message)")
        #endif
    }
}
