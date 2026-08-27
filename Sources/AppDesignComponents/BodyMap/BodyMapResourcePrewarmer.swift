#if canImport(UIKit)
import Foundation

/// Prepares BodyMap mask resources before a BodyMap is presented.
public enum BodyMapResourcePrewarmer {
    public static func prewarm(
        _ configuration: BodyMapResourceConfiguration
    ) async throws {
        let bundle = configuration.bundle

        async let front: Void = BodyMapMaskPrewarmer.prewarm(
            model: configuration.model,
            side: .front,
            bundle: bundle
        )
        async let back: Void = BodyMapMaskPrewarmer.prewarm(
            model: configuration.model,
            side: .back,
            bundle: bundle
        )

        _ = try await (front, back)
    }
}
#endif
