import MetalKit

public final class BodyMapTextureLoader {
    private let device: MTLDevice
    private let bundle: Bundle

    public init(
        device: MTLDevice,
        bundle: Bundle = .module
    ) {
        self.device = device
        self.bundle = bundle
    }

    public func loadTexture(named name: String) -> MTLTexture? {
        guard let url = bundle.url(forResource: name, withExtension: nil) else {
            return nil
        }

        let loader = MTKTextureLoader(device: device)

        return try? loader.newTexture(
            URL: url,
            options: [
                MTKTextureLoader.Option.SRGB: false
            ]
        )
    }
}
