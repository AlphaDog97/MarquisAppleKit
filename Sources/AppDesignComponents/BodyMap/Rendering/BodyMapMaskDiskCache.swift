#if canImport(UIKit)
import Foundation

struct BodyMapPersistedMaskSet {
    let width: Int
    let height: Int
    let assetBounds: [SIMD4<Float>]
    let storage: Data
    let sliceByteOffset: Int

    var sliceCount: Int { assetBounds.count + 1 }
    var bytesPerSlice: Int { width * height }
}

enum BodyMapMaskDiskCache {
    private static let magic = Data([0x4D, 0x41, 0x52, 0x51, 0x42, 0x4D, 0x30, 0x31])
    private static let formatVersion: UInt32 = 1

    // Bump when anatomy resources, rasterization scale or persisted layout change.
    // Keep this independent from app/package build numbers so identical masks can
    // be reused after an update.
    private static let directoryName = "MarquisBodyMapMasks-v1-scale2"

    static func load(
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle,
        expectedAssetCount: Int
    ) -> BodyMapPersistedMaskSet? {
        guard let url = try? fileURL(
            model: model,
            side: side,
            bundle: bundle
        ), let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }

        return decode(data, expectedAssetCount: expectedAssetCount)
    }

    static func storeInBackground(
        masks: [BodyMapMaskBitmap],
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) {
        let job = BodyMapMaskDiskWriteJob(
            masks: masks,
            model: model,
            side: side,
            bundle: bundle
        )

        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: 800_000_000)
            try? job.run()
        }
    }

    static func store(
        masks: [BodyMapMaskBitmap],
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) throws {
        guard let first = masks.first else { return }

        let assetBounds = masks.dropFirst().map(\.normalizedBounds)
        let sliceBytes = first.width * first.height
        var data = Data()
        data.reserveCapacity(
            magic.count
                + MemoryLayout<UInt32>.size * 5
                + assetBounds.count * MemoryLayout<Float>.size * 4
                + masks.count * sliceBytes
        )

        data.append(magic)
        data.appendLittleEndian(formatVersion)
        data.appendLittleEndian(UInt32(first.width))
        data.appendLittleEndian(UInt32(first.height))
        data.appendLittleEndian(UInt32(masks.count))
        data.appendLittleEndian(UInt32(assetBounds.count))

        for bounds in assetBounds {
            data.appendLittleEndian(bounds.x.bitPattern)
            data.appendLittleEndian(bounds.y.bitPattern)
            data.appendLittleEndian(bounds.z.bitPattern)
            data.appendLittleEndian(bounds.w.bitPattern)
        }

        for mask in masks {
            data.append(contentsOf: mask.bytes)
        }

        let url = try fileURL(
            model: model,
            side: side,
            bundle: bundle
        )
        try data.write(to: url, options: .atomic)
    }

    private static func decode(
        _ data: Data,
        expectedAssetCount: Int
    ) -> BodyMapPersistedMaskSet? {
        guard data.starts(with: magic) else { return nil }

        var reader = Reader(data: data, offset: magic.count)
        guard reader.readUInt32() == formatVersion,
              let widthValue = reader.readUInt32(),
              let heightValue = reader.readUInt32(),
              let sliceCountValue = reader.readUInt32(),
              let boundsCountValue = reader.readUInt32() else {
            return nil
        }

        let width = Int(widthValue)
        let height = Int(heightValue)
        let sliceCount = Int(sliceCountValue)
        let boundsCount = Int(boundsCountValue)
        guard width > 0,
              height > 0,
              boundsCount == expectedAssetCount,
              sliceCount == expectedAssetCount + 1 else {
            return nil
        }

        var assetBounds: [SIMD4<Float>] = []
        assetBounds.reserveCapacity(boundsCount)
        for _ in 0..<boundsCount {
            guard let x = reader.readFloat(),
                  let y = reader.readFloat(),
                  let z = reader.readFloat(),
                  let w = reader.readFloat() else {
                return nil
            }
            assetBounds.append(SIMD4(x, y, z, w))
        }

        let (bytesPerSlice, sliceOverflow) = width.multipliedReportingOverflow(by: height)
        let (totalSliceBytes, totalOverflow) = bytesPerSlice.multipliedReportingOverflow(
            by: sliceCount
        )
        guard !sliceOverflow,
              !totalOverflow,
              reader.offset + totalSliceBytes == data.count else {
            return nil
        }

        return BodyMapPersistedMaskSet(
            width: width,
            height: height,
            assetBounds: assetBounds,
            storage: data,
            sliceByteOffset: reader.offset
        )
    }

    private static func fileURL(
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) throws -> URL {
        let fileManager = FileManager.default
        let cacheRoot = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let bundleIdentifier = bundle.bundleIdentifier ?? "MarquisAppleKit.BodyMap"
        let directory = cacheRoot
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(bundleIdentifier, isDirectory: true)

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let modelName = model == .male ? "male" : "female"
        return directory.appendingPathComponent(
            "\(modelName)-\(side.rawValue).maskset"
        )
    }

    private struct Reader {
        let data: Data
        var offset: Int

        mutating func readUInt32() -> UInt32? {
            let size = MemoryLayout<UInt32>.size
            guard offset + size <= data.count else { return nil }
            let value = data.withUnsafeBytes { bytes in
                bytes.loadUnaligned(
                    fromByteOffset: offset,
                    as: UInt32.self
                )
            }
            offset += size
            return UInt32(littleEndian: value)
        }

        mutating func readFloat() -> Float? {
            guard let bitPattern = readUInt32() else { return nil }
            return Float(bitPattern: bitPattern)
        }
    }
}

private final class BodyMapMaskDiskWriteJob: @unchecked Sendable {
    private let masks: [BodyMapMaskBitmap]
    private let model: BodyMapModel
    private let side: BodyMapAnatomySide
    private let bundle: Bundle

    init(
        masks: [BodyMapMaskBitmap],
        model: BodyMapModel,
        side: BodyMapAnatomySide,
        bundle: Bundle
    ) {
        self.masks = masks
        self.model = model
        self.side = side
        self.bundle = bundle
    }

    func run() throws {
        try BodyMapMaskDiskCache.store(
            masks: masks,
            model: model,
            side: side,
            bundle: bundle
        )
    }
}

private extension Data {
    mutating func appendLittleEndian(_ value: UInt32) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
#endif
