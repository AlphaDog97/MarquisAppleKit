#include <metal_stdlib>
using namespace metal;

namespace {
constant float kBodyMapBlurWeights[9] = {
    0.02763055,
    0.06628225,
    0.12383154,
    0.18017382,
    0.20416369,
    0.18017382,
    0.12383154,
    0.06628225,
    0.02763055
};

constexpr sampler bodyMapSampler(
    coord::normalized,
    address::clamp_to_zero,
    filter::linear
);
}

struct BodyMapBlurUniforms {
    float radius;
    float padding;
    float2 axis;
};

struct BodyMapFrameUniforms {
    float4 baseColor;
    float4 metadata;
};

struct BodyMapAssetUniforms {
    float4 fillColor;
    float4 glowColor;
    float4 shadowColor;
    float4 values;
};

struct BodyMapVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

kernel void bodyMapDownsampleMask(
    texture2d_array<float, access::sample> source [[texture(0)]],
    texture2d_array<float, access::write> destination [[texture(1)]],
    uint3 gid [[thread_position_in_grid]]
) {
    const uint width = destination.get_width();
    const uint height = destination.get_height();
    const uint slices = destination.get_array_size();
    if (gid.x >= width || gid.y >= height || gid.z >= slices) {
        return;
    }

    const float2 uv = (float2(gid.xy) + 0.5)
        / float2(float(width), float(height));
    const float value = source.sample(bodyMapSampler, uv, gid.z).r;
    destination.write(float4(value, 0.0, 0.0, 1.0), gid.xy, gid.z);
}

kernel void bodyMapBlurMask(
    texture2d_array<float, access::read> source [[texture(0)]],
    texture2d_array<float, access::write> destination [[texture(1)]],
    constant BodyMapBlurUniforms &uniforms [[buffer(0)]],
    uint3 gid [[thread_position_in_grid]]
) {
    const uint width = source.get_width();
    const uint height = source.get_height();
    const uint slices = source.get_array_size();
    if (gid.x >= width || gid.y >= height || gid.z >= slices) {
        return;
    }

    float value = 0.0;
    for (int tap = -4; tap <= 4; ++tap) {
        const float normalizedTap = float(tap) / 4.0;
        const int offset = int(round(normalizedTap * uniforms.radius));
        const int2 requested = int2(gid.xy) + int2(
            round(uniforms.axis.x * float(offset)),
            round(uniforms.axis.y * float(offset))
        );
        const uint2 coordinate = uint2(
            clamp(requested.x, 0, int(width) - 1),
            clamp(requested.y, 0, int(height) - 1)
        );
        value += source.read(coordinate, gid.z).r
            * kBodyMapBlurWeights[tap + 4];
    }

    destination.write(float4(value, 0.0, 0.0, 1.0), gid.xy, gid.z);
}

vertex BodyMapVertexOut bodyMapVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[3] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };
    const float2 texCoords[3] = {
        float2(0.0, 1.0),
        float2(2.0, 1.0),
        float2(0.0, -1.0)
    };

    BodyMapVertexOut output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    output.texCoord = texCoords[vertexID];
    return output;
}

static float3 bodyMapSRGBToLinear(float3 value) {
    const float3 low = value / 12.92;
    const float3 high = pow((value + 0.055) / 1.055, float3(2.4));
    return select(high, low, value <= 0.04045);
}

static float4 bodyMapSourceOver(
    float4 destination,
    float3 sourceColor,
    float sourceAlpha
) {
    const float alpha = clamp(sourceAlpha, 0.0, 1.0);
    return float4(
        sourceColor * alpha + destination.rgb * (1.0 - alpha),
        alpha + destination.a * (1.0 - alpha)
    );
}

static float4 bodyMapScreenOver(
    float4 destination,
    float3 sourceColor,
    float sourceAlpha
) {
    const float alpha = clamp(sourceAlpha, 0.0, 1.0);
    if (alpha <= 0.0) {
        return destination;
    }

    const float destinationAlpha = destination.a;
    const float3 destinationColor = destinationAlpha > 0.0001
        ? destination.rgb / destinationAlpha
        : float3(0.0);
    const float3 blended = 1.0
        - (1.0 - destinationColor) * (1.0 - sourceColor);
    const float outputAlpha = alpha + destinationAlpha - alpha * destinationAlpha;
    const float3 outputColor =
        (1.0 - destinationAlpha) * sourceColor * alpha
        + (1.0 - alpha) * destination.rgb
        + alpha * destinationAlpha * blended;

    return float4(outputColor, outputAlpha);
}

fragment float4 bodyMapFragment(
    BodyMapVertexOut input [[stage_in]],
    texture2d_array<float, access::sample> masks [[texture(0)]],
    texture2d_array<float, access::sample> glowMasks [[texture(1)]],
    texture2d_array<float, access::sample> shadowMasks [[texture(2)]],
    texture2d_array<float, access::sample> selectionMasks [[texture(3)]],
    constant BodyMapFrameUniforms &frame [[buffer(0)]],
    constant BodyMapAssetUniforms *assets [[buffer(1)]]
) {
    const float2 uv = input.texCoord;
    const uint assetCount = uint(frame.metadata.x);

    const float baseMask = masks.sample(bodyMapSampler, uv, 0).r;
    const float baseAlpha = baseMask * frame.baseColor.a;
    float4 result = float4(
        bodyMapSRGBToLinear(frame.baseColor.rgb) * baseAlpha,
        baseAlpha
    );

    for (uint index = 0; index < assetCount; ++index) {
        const uint slice = index + 1;
        const BodyMapAssetUniforms asset = assets[index];
        const float fillMask = masks.sample(bodyMapSampler, uv, slice).r;

        const float blurredGlowMask = glowMasks.sample(bodyMapSampler, uv, slice).r;
        const float glowMask = max(blurredGlowMask - fillMask, 0.0);
        const float3 glowColor = bodyMapSRGBToLinear(asset.glowColor.rgb);
        result = bodyMapScreenOver(
            result,
            glowColor,
            glowMask * asset.values.y * asset.glowColor.a
        );

        const float shadowMask = shadowMasks.sample(bodyMapSampler, uv, slice).r;
        const float3 shadowColor = bodyMapSRGBToLinear(asset.shadowColor.rgb);
        result = bodyMapSourceOver(
            result,
            shadowColor,
            shadowMask * asset.values.z * asset.shadowColor.a
        );

        if (asset.values.w > 0.001) {
            const float selectionMask = selectionMasks.sample(
                bodyMapSampler,
                uv,
                slice
            ).r;
            result = bodyMapSourceOver(
                result,
                float3(1.0),
                selectionMask * 0.65 * asset.values.w
            );
        }

        const float3 fillColor = bodyMapSRGBToLinear(asset.fillColor.rgb);
        result = bodyMapSourceOver(
            result,
            fillColor,
            fillMask * asset.values.x * asset.fillColor.a
        );
    }

    return result;
}
