#include <metal_stdlib>
using namespace metal;

static float bodyMapMorphologySmoothMix(
    float source,
    float target,
    float value,
    float lower,
    float upper
) {
    return mix(source, target, smoothstep(lower, upper, value));
}

static float bodyMapMorphologyTorsoScale(
    float y,
    float4 torsoScales,
    float4 limbScales
) {
    const float shoulders = torsoScales.x;
    const float chest = torsoScales.y;
    const float waist = torsoScales.z;
    const float hips = torsoScales.w;
    const float thighs = limbScales.z;
    const float calves = limbScales.w;

    if (y <= 0.10) {
        return 1.0;
    }
    if (y <= 0.20) {
        return bodyMapMorphologySmoothMix(1.0, shoulders, y, 0.10, 0.20);
    }
    if (y <= 0.29) {
        return bodyMapMorphologySmoothMix(shoulders, chest, y, 0.20, 0.29);
    }
    if (y <= 0.41) {
        return bodyMapMorphologySmoothMix(chest, waist, y, 0.29, 0.41);
    }
    if (y <= 0.52) {
        return bodyMapMorphologySmoothMix(waist, hips, y, 0.41, 0.52);
    }
    if (y <= 0.66) {
        return bodyMapMorphologySmoothMix(hips, thighs, y, 0.52, 0.66);
    }
    if (y <= 0.84) {
        return bodyMapMorphologySmoothMix(thighs, calves, y, 0.66, 0.84);
    }
    if (y <= 0.94) {
        return bodyMapMorphologySmoothMix(calves, 1.0, y, 0.84, 0.94);
    }
    return 1.0;
}

static float bodyMapMorphologyArmScale(
    float y,
    float4 limbScales
) {
    const float upperArms = limbScales.x;
    const float forearms = limbScales.y;

    if (y <= 0.18) {
        return 1.0;
    }
    if (y <= 0.28) {
        return bodyMapMorphologySmoothMix(1.0, upperArms, y, 0.18, 0.28);
    }
    if (y <= 0.38) {
        return upperArms;
    }
    if (y <= 0.52) {
        return bodyMapMorphologySmoothMix(
            upperArms,
            forearms,
            y,
            0.38,
            0.52
        );
    }
    if (y <= 0.62) {
        return bodyMapMorphologySmoothMix(forearms, 1.0, y, 0.52, 0.62);
    }
    return 1.0;
}

static float bodyMapMorphologyArmInfluence(float2 uv) {
    const float horizontal = smoothstep(0.19, 0.27, abs(uv.x - 0.5));
    const float verticalEntry = smoothstep(0.16, 0.23, uv.y);
    const float verticalExit = 1.0 - smoothstep(0.58, 0.66, uv.y);
    return horizontal * verticalEntry * verticalExit;
}

static float2 bodyMapMorphologySourceUV(
    float2 uv,
    float4 torsoScales,
    float4 limbScales
) {
    const float torsoScale = bodyMapMorphologyTorsoScale(
        uv.y,
        torsoScales,
        limbScales
    );
    const float armScale = bodyMapMorphologyArmScale(uv.y, limbScales);
    const float scale = mix(
        torsoScale,
        armScale,
        bodyMapMorphologyArmInfluence(uv)
    );

    return float2(
        0.5 + (uv.x - 0.5) / scale,
        uv.y
    );
}

[[ stitchable ]] float2 bodyMapMorphologyDistortion(
    float2 position,
    float2 size,
    float4 torsoScales,
    float4 limbScales
) {
    if (size.x <= 0.0 || size.y <= 0.0) {
        return position;
    }

    const float2 uv = position / size;
    return bodyMapMorphologySourceUV(uv, torsoScales, limbScales) * size;
}
