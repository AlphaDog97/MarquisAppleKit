import MetalKit

struct BodyMapRendererConfiguration {
    let device: MTLDevice?
    let textureName: String
    let shaderConfiguration: BodyMapShaderConfiguration

    init(
        device: MTLDevice? = MTLCreateSystemDefaultDevice(),
        textureName: String = "body_map_male",
        shaderConfiguration: BodyMapShaderConfiguration = .init()
    ) {
        self.device = device
        self.textureName = textureName
        self.shaderConfiguration = shaderConfiguration
    }
}
