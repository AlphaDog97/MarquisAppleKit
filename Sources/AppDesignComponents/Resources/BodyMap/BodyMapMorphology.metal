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
    float4 torsoScales
) {
    const float shoulders = torsoScales.x;
    const float chest = torsoScales.y;
    const float waist = torsoScales.z;
    const float hips = torsoScales.w;

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
    if (y <= 0.60) {
        return bodyMapMorphologySmoothMix(hips, 1.0, y, 0.52, 0.60);
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

static float bodyMapMorphologyLegScale(
    float y,
    float4 limbScales
) {
    const float thighs = limbScales.z;
    const float calves = limbScales.w;

    if (y <= 0.52) {
        return 1.0;
    }
    if (y <= 0.62) {
        return bodyMapMorphologySmoothMix(1.0, thighs, y, 0.52, 0.62);
    }
    if (y <= 0.72) {
        return thighs;
    }
    if (y <= 0.84) {
        return bodyMapMorphologySmoothMix(thighs, calves, y, 0.72, 0.84);
    }
    if (y <= 0.94) {
        return bodyMapMorphologySmoothMix(calves, 1.0, y, 0.84, 0.94);
    }
    return 1.0;
}

static float bodyMapMorphologyArmInfluence(float2 uv) {
    const float horizontal = smoothstep(0.19, 0.27, abs(uv.x - 0.5));
    const float verticalEntry = smoothstep(0.16, 0.23, uv.y);
    const float verticalExit = 1.0 - smoothstep(0.58, 0.66, uv.y);
    return horizontal * verticalEntry * verticalExit;
}

static float bodyMapMorphologyLegInfluence(float y) {
    return smoothstep(0.50, 0.60, y)
        * (1.0 - smoothstep(0.93, 0.98, y));
}

static float bodyMapMorphologyArmCenterDistance(float y) {
    if (y <= 0.28) {
        return 0.23;
    }
    if (y <= 0.52) {
        return bodyMapMorphologySmoothMix(0.23, 0.31, y, 0.28, 0.52);
    }
    return 0.31;
}

static float bodyMapMorphologyLegCenterDistance(float y) {
    if (y <= 0.72) {
        return 0.105;
    }
    if (y <= 0.88) {
        return bodyMapMorphologySmoothMix(0.105, 0.115, y, 0.72, 0.88);
    }
    return 0.115;
}

static float bodyMapMorphologyLimbCenter(
    float outputX,
    float distanceFromMidline
) {
    const float delta = outputX - 0.5;
    const float direction = delta < 0.0 ? -1.0 : 1.0;
    const float separation = smoothstep(0.0, 0.06, abs(delta));
    return 0.5 + direction * distanceFromMidline * separation;
}

static float bodyMapMorphologyScaledSourceX(
    float outputX,
    float centerX,
    float scale
) {
    return centerX + (outputX - centerX) / scale;
}

static float2 bodyMapMorphologySourceUV(
    float2 uv,
    float4 torsoScales,
    float4 limbScales
) {
    const float torsoSourceX = bodyMapMorphologyScaledSourceX(
        uv.x,
        0.5,
        bodyMapMorphologyTorsoScale(uv.y, torsoScales)
    );

    const float legSourceX = bodyMapMorphologyScaledSourceX(
        uv.x,
        bodyMapMorphologyLimbCenter(
            uv.x,
            bodyMapMorphologyLegCenterDistance(uv.y)
        ),
        bodyMapMorphologyLegScale(uv.y, limbScales)
    );
    const float lowerBodySourceX = mix(
        torsoSourceX,
        legSourceX,
        bodyMapMorphologyLegInfluence(uv.y)
    );

    const float armSourceX = bodyMapMorphologyScaledSourceX(
        uv.x,
        bodyMapMorphologyLimbCenter(
            uv.x,
            bodyMapMorphologyArmCenterDistance(uv.y)
        ),
        bodyMapMorphologyArmScale(uv.y, limbScales)
    );
    const float sourceX = mix(
        lowerBodySourceX,
        armSourceX,
        bodyMapMorphologyArmInfluence(uv)
    );

    return float2(sourceX, uv.y);
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
