#include <metal_stdlib>
using namespace metal;

struct BodyMapVertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct BodyMapShaderUniform {
    float intensity;
    float glowEnergy;
    float shadowEnergy;
};

vertex BodyMapVertexOut bodyMapVertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
    };

    BodyMapVertexOut output;
    output.position = float4(positions[vertexID], 0, 1);
    output.textureCoordinate = positions[vertexID] * 0.5 + 0.5;
    return output;
}

fragment float4 bodyMapFragment(
    BodyMapVertexOut input [[stage_in]],
    texture2d<float> bodyTexture [[texture(0)]],
    constant BodyMapShaderUniform& uniform [[buffer(1)]]
) {
    constexpr sampler sampler(filter::linear);

    float4 color = bodyTexture.sample(sampler, input.textureCoordinate);
    color.rgb *= uniform.intensity;
    color.rgb += uniform.glowEnergy;
    color.rgb *= (1.0 - uniform.shadowEnergy);

    return color;
}
