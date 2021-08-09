#ifndef MYENGINE_URP_WET_INCLUDED
#define MYENGINE_URP_WET_INCLUDED


#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

#include "./MyEngine_Common.hlsl"

half _Wetness;
half _WetDarkness;
half _WetSmoothness;
half _WetSkinPorosity;
half _WetHairPorosity;
half _WetRefractionScale;

// Ripple

TEXTURE2D(_RippleTexture); SAMPLER(sampler_RippleTexture);
half _RippleIntensity;
half _RippleTiling;
half _RippleSpeed;
half _RippleBumpScale;

// Flow
TEXTURE2D(_WaterFlowTexture); SAMPLER(sampler_WaterFlowTexture);
half _WaterFlowIntensity;
half _WaterFlowTiling;
half _WaterFlowSpeed;

half Roughness2Porosity(half roughness)
{
    return saturate((roughness - 0.5) / 0.4 );
}

void WetBRDF(half metallic, inout half3 diffuseColor, inout half smoothness)
{
    half porosity = Roughness2Porosity( 1 - smoothness);
    half factor = lerp( 1, _WetDarkness, ( 1 - metallic) * porosity );
    diffuseColor *= lerp(1, factor, _Wetness);
    smoothness = lerp(_WetSmoothness, smoothness, lerp(1, factor, 0.5 * _Wetness));
    smoothness = clamp(smoothness, 0, 1);
}

void WetCustomBRDF(half metallic, half porosity, half wetDarkness, inout half3 diffuseColor, inout half smoothness)
{
    half factor = lerp(1, wetDarkness, (1- metallic) * porosity);
    diffuseColor *= lerp(1, factor, _Wetness);
    smoothness = lerp(_WetSmoothness, smoothness, lerp(1, factor, 0.5 * _Wetness));
    smoothness = clamp(smoothness, 0, 1);
}

void WetRoleBRDF(half metallic, half3 normalWS, half isSkin, inout half3 diffuseColor, inout half smoothness) 
{
    // skin
    half skinSmoothness = smoothness;
    half3 skinDiffuseColor = diffuseColor * ( 1 + _Wetness);
    WetCustomBRDF(metallic, _WetSkinPorosity, 0.2, skinDiffuseColor, skinSmoothness);

    //normaliz
    WetBRDF(metallic, diffuseColor, smoothness);

    diffuseColor = lerp(diffuseColor, skinDiffuseColor, isSkin);
    smoothness = lerp(smoothness, skinSmoothness, isSkin);
}

void WetTerrainBRDF(half metallic, inout half3 diffuseColor, inout half smoothness, half wetness) 
{
    half porosity = Roughness2Porosity(1 - smoothness);
    half factor = lerp(1, _WetDarkness, (1 - metallic) * porosity);

    diffuseColor *= lerp(1, factor, wetness);
    smoothness = lerp(_WetSmoothness, smoothness, lerp(1, factor, 0.5 * wetness));
    smoothness = clamp(smoothness, 0, 1);
}

//Ripple 
half3 ComputeRipple(TEXTURE2D_PARAM(_BaseRippleTexture, sampler_BaseRippleTexture), float2 uv, float time, half weight)
{
    float4 ripple = SAMPLE_TEXTURE2D(_BaseRippleTexture, sampler_BaseRippleTexture, uv);

    ripple.yz = ripple.yz *2 - 1;

    half dropFrac = frac(ripple.w + time);

    half timeFrac = dropFrac - 1.0f + ripple.x;

    half dropFactor = saturate(0.2f + weight * 0.8f - dropFrac);

    half finalFactor = dropFactor * ripple.x * sin(clamp(timeFrac * 9.0f, 0.0f, 3.0f) * 3.14159265359);

    return half3(ripple.yz * finalFactor, 1);
}

half3 GetRippleNormalTS(float3 positionWS, half3 normalWS)
{
    float2 uv = positionWS.xz * _RippleTiling;
    half3 rippleNormalTS = MyUnpackNormal(SAMPLE_TEXTURE2D(_RippleTexture, sampler_RippleTexture, uv));
    rippleNormalTS = lerp(half3(0, 0, 1), rippleNormalTS, _RippleIntensity);
    return rippleNormalTS;
}

half3 GetWaterFlowNormalTS(float3 positionWS, half3 normalWS, float4 positionCS)
{
    float4 uv = float4(positionWS.xy, positionWS.zy);
    float4 flowDirection = float4(0, 1, 0, 1) * _WaterFlowSpeed;
    uv = uv + flowDirection * _Time.y;
    uv *= _WaterFlowTiling;

    half3 flowNormalTS1 = MyUnpackNormal( SAMPLE_TEXTURE2D(_WaterFlowTexture, sampler_WaterFlowTexture, uv.xy));
    half3 flowNormalTS2 = MyUnpackNormal( SAMPLE_TEXTURE2D(_WaterFlowTexture, sampler_WaterFlowTexture, uv.zw));

    half3 flowNormalTS = flowNormalTS1 * normalWS.z + flowNormalTS2 * normalWS.x;

    float distanceFadeFactor = positionCS.z * _ZBufferParams.z;
    
    #if  UNITY_REVERSED_Z != 1 
        distanceFadeFactor = positionCS.z * rcp(positionCS.w);
    #endif

    half flowWeight = clamp(distanceFadeFactor * _WaterFlowIntensity, 0, 0.5);

    flowNormalTS = lerp(half3(0, 0, 1), flowNormalTS, flowWeight);

    return flowNormalTS;

}

half3 GetWetNormalTS(float3 positionWS, half3 normalWS, float4 positionCS)
{
    half3 rippleNormalTS = GetRippleNormalTS (positionWS, normalWS);
    half3 flowNormalTS = GetWaterFlowNormalTS(positionWS, normalWS, positionCS);

    half faceWeight = max(0, dot(normalWS, half3(0, 1, 0)));
    faceWeight *= faceWeight;

    return lerp(flowNormalTS, rippleNormalTS, faceWeight);
}


#endif