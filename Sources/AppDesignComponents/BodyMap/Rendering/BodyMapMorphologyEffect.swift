import SwiftUI

extension View {
    @ViewBuilder
    func bodyMapMorphologyEffect(_ morphology: BodyMapMorphology) -> some View {
        if morphology.isNeutral {
            self
        } else {
            visualEffect { content, proxy in
                content.distortionEffect(
                    ShaderLibrary.bundle(.module).bodyMapMorphologyDistortion(
                        .float2(
                            Float(proxy.size.width),
                            Float(proxy.size.height)
                        ),
                        .float4(
                            Float(morphology.shoulders),
                            Float(morphology.chest),
                            Float(morphology.waist),
                            Float(morphology.hips)
                        ),
                        .float4(
                            Float(morphology.upperArms),
                            Float(morphology.forearms),
                            Float(morphology.thighs),
                            Float(morphology.calves)
                        )
                    ),
                    maxSampleOffset: CGSize(
                        width: proxy.size.width * 0.08,
                        height: 0
                    )
                )
            }
        }
    }
}
