import MetalKit

public final class BodyMapTextureLoader {
    private let device: MTLDevice

    public init(device: MTLDevice) {
        self.device = device
    }

    public func loadTexture(named name: String) -> MTLTexture? {
        let loader = MTKTextureLoader(device: device)

        guard let image = UIImage(named: name) else {
            return nil
        }

        return try? loader.newTexture(
            cgImage: image.cgImage,
            options: [
                MTKTextureLoader.Option.SRGB: false
            ]
        )
    }
}
