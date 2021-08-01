#ifndef MYENGINE_URP_SSR_INCLUDED
#define MYENGINE_URP_SSR_INCLUDED

#if defined(_SSR_ORTHO_ON)
    inline float GetOrthoEyeDepth(float rawDepth)
    {
        #if defined(_UNITY_REVERSED_Z)
            #if UNITY_REVERSED_Z == 1
                rawDepth = 1.0f - rawDepth;
            #endif
        #endif
        return lerp(_ProjectionParams.y, _ProjectionParams.z, rawDepth);
    }
#endif

float UVJitter(in float2 uv)
{
    float dotUV = frac( dot(uv, float2(0.06711056, 0.00583715)));

    return frac( 52.9829189 * dotUV  );
}

void SSRRayConvert(float3 worldPos, out float4 clipPos, out float3 screenPos)
{
    clipPos = TransformWorldToHClip(worldPos);
    float k = rcp(clipPos.w);

    screenPos.xy = ComputeScreenPos(clipPos).xy * k;

    #if defined(_SSR_ORTHO_ON)
        screenPos.z = GetOrthoEyeDepth(clipPos.z);
        clipPos.w = screenPos.z;
    #else
        screenPos.z = k;
    #endif

    #if defined(UNITY_SINGLE_PASS_STEREO)
        screenPos.xy = UnityStereoTransformScreenSpaceTex(screenPos.xy);
    #endif

}

#endif