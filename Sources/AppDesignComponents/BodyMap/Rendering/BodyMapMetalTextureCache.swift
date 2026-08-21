#if canImport(UIKit)
import Foundation
import Metal

final class BodyMapMetalTextureCache: @unchecked Sendable {
    static let shared = BodyMapMetalTextureCache()

    private struct Key: Hashable {
        let deviceName: String
        let bundlePath: String
        let model: String
        let side: String
    }

    private let lock = NSLock()
    private let capacity = 8
    private var values: [Key: BodyMapMaskTextureSet] = [:]
    private var accessOrder: [Key] = []

    private init() {}

    func maskSet(
        device: MTLDevice,
        bundle: Bundle,
        model: BodyMapModel,
        side: BodyMapAnatomySide
    ) -> BodyMapMaskTextureSet? {
        let key = makeKey(
            device: device,
            bundle: bundle,
            model: model,
            side: side
        )

        lock.lock()
        defer { lock.unlock() }
        guard let value = values[key] else { return nil }
        markRecentlyUsed(key)
        return value
    }

    func store(
        _ value: BodyMapMaskTextureSet,
        device: MTLDevice,
        bundle: Bundle,
        model: BodyMapModel,
        side: BodyMapAnatomySide
    ) {
        let key = makeKey(
            device: device,
            bundle: bundle,
            model: model,
            side: side
        )

        lock.lock()
        defer { lock.unlock() }
        values[key] = value
        markRecentlyUsed(key)

        while accessOrder.count > capacity {
            values[accessOrder.removeFirst()] = nil
        }
    }

    private func makeKey(
        device: MTLDevice,
        bundle: Bundle,
        model: BodyMapModel,
        side: BodyMapAnatomySide
    ) -> Key {
        Key(
            deviceName: device.name,
            bundlePath: bundle.bundlePath,
            model: model.resourcePrefix,
            side: side.rawValue
        )
    }

    private func markRecentlyUsed(_ key: Key) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
}
#endif
