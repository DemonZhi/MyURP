#ifndef MYENGINE_URP_LIT_BASE
#define MYENGINE_URP_LIT_BASE

// URP
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

// MyEngine
#include "./MyEngine_Common.hlsl"
#include "./MyEngine_Fog.hlsl"
#include "./MyEngine_Scene_Lighting.hlsl"
#include "./MyEngine_Scene_Wind.hlsl"
#include "./MyEngine_Scene_Wet.hlsl"

#undef BUMP_SACLE_NOT_SUPPORTED

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;

//Top Color
half4 _TopColor;
float4 _TopMap_ST;
float4 _TopNoiseMap_ST;
half _TopOffset;
half _TopAOOffset;
half _TopContrast;
half _TopIntensity;
float4 _TopBumpMap_ST;

half4 _EmissionColor;
half _EmissionIntensity;
half _Cutoff;
half _MetallicScale;
half _RoughnessScale;

half _ReflectionPower;
half _SSRSampleStep;
half _SSRMaxSampleCount;
half _SSRJitter;
half _SSRIntensity;
half _SSRBlurX;
half _SSRBlurY;

half _FlagWaveSpeed;
half _FlagWaveFrequencyScale;
half4 _FlagWaveWaveScale;
half _FlagWaveLengthOffset;
half4 _FlagWaveWindScale;
half _VertexOffsetMapU;
half _VertexOffsetMapV;
half _VertexOffsetIntensity;

half4 _StreamMap_ST;
half _StreamFactor;
half _StreamColorFactor;
half _StreamTexFactor;
half _StreamOffsetX;
half _StreamOffsetY;

float4 _LightDecalTilingOffset;
half _LightDecalIntensity;




CBUFFER_END

TEXTURE2D(_NormalMap);      SAMPLE(sampler_NormalMap);
TEXTURE2D(_MetallicGlossMap);      SAMPLE(sampler_MetallicGlossMap);
TEXTURE2D(_CubemapEmissionCubemap);      SAMPLE(sampler_CubemapEmissionCubemap);

TEXTURE2D(_TopMap);      SAMPLE(sampler_TopMap);
TEXTURE2D(_TopNoiseMap);      SAMPLE(sampler_TopNoiseMap);
TEXTURE2D(_TopBumpMap);      SAMPLE(sampler_TopBumpMap);
TEXTURE2D(_VertexOffsetMap);      SAMPLE(sampler_VertexOffsetMap);
TEXTURE2D(_SteamMap);      SAMPLE(sampler_SteamMap);
TEXTURE2D(_LightDecalMap);      SAMPLE(sampler_LightDecalMap);

#if defined(_REFLECTIONTYPE_SSR)
TEXTURE2D(_CameraDepthTexture);      SAMPLE(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);      SAMPLE(sampler_LinearClamp);
#include "../Base/Includes/MyEngine_SSR.hlsl"
half4 GetSSR(float4 positionCS, half Nov, float2 screenUV, float3 positionWS, float3 reflectDir)
{    
    half3 ssrColor = half3(0, 0, 0);
    float3 uvz = GetSSRUVZ(positionCS, Nov, screenUV, positionWS, reflectDir, _SSRMaxSampleCount, _SSRSampleStep, _SSRJitter);
    float2 off1 = float2(1.3846153846, 1.3846153846) * _SSRBlurX / _ScreenParams.x;
    float2 off2 = float2(3.2307692308, 3.2307692308) * _SSRBlurY / _ScreenParams.y;
    float2 sampleUV = uvz.xy;

    ssrColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp, sampleUV).rgb * 0.2270270270;
    ssrColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp, sampleUV + off1).rgb * 0.3162162162;
    ssrColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp, sampleUV - off1).rgb * 0.3162162162;
    ssrColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp, sampleUV + off2).rgb * 0.0702702703;
    ssrColor += SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp, sampleUV - off2).rgb * 0.0702702703;
    ssrColor *= _SSRIntensity;

    return half4(ssrColor, uvz.z);
}

#endif



struct Attributes
{
    float4      positionOS          :   POSITION;
    float4      normalOS            :   NORMAL;
    half4       color               :   COLOR;
    float2      texcoord            :   TEXCOORD0;    
    float2      lightmapUV            :   TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS :  SV_POSITION;
    #if defined(_SGENGINE_DEBUG)
        half4 vertexColor   : COLOR;
    #endif

    float2 uv : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    float3 positionWS : TEXCOORD2;

    #if defined(_NORMALMAP)&& defined(_USE_NORMALMAP)
        half normalWS : TEXCOORD3;
        half4 tangentWS : TEXCOORD4;
        half4 bitangentWS : TEXCOORD5;
    #else
        half3 normalWS : TEXCOORD3;
        half3 viewDirWS: TEXCOORD4;
    #endif

    half4 fogFactorAndVertexLight   :   TEXCOORD6; // x fogFactor, yzw: vertexLight

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        float4 shadowCoord  :   TEXCOORD7;
    #endif

    float2 fogAtten :   TEXCOORD8;
    
    #if defined(_REFLECTIONTYPE_REALTIME) || defined(_REFLECTIONTYPE_SSR)
        float4 screenPos  :   TEXCOORD9;
    #endif

    #if defined(_STREAM_ON) 
        float2 streamUV  :   TEXCOORD10;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

inline void InitializeStandardLitSurfaceData(Varyings input, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    outSurfaceData.metallic = saturate(specGloss.g * _MetallicScale);
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceData.smoothness = saturate(1 - specGloss.r * _RoughnessScale);
    outSurfaceData.normalTS = MyUnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
    outSurfaceData.occlusion = specGloss.b;
    #if defined(_EMISSION)
        outSurfaceData.emission = SampleEmission(input.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)) * _EmissionIntensity;        
    #else
        outSurfaceData.emission = half3(0, 0, 0);
    #endif

    outSurfaceData.clearCoatMask = 0;
    outSurfaceData.clearCoatSmoothness = 0;
}

void InitializeInputData(Varyings input, half3 normalTX, out InputData inputData)
{
    inputData = (InputData)0;
    inputData.positionWS = input.positionWS;

    #if defined(_NORMALMAP) && defined(_USE_NORMALMAP)
        half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
        inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
    #else
        half3 viewDirWS = input.viewDirWS;
        inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = SafeNormalize_Half3(inputData.normalWS);
    viewDirWS = SafeNormalize_Half3(viewDirWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined (REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
    #else
        inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);

#if defined(_SCREEN_SPACE_OCCLUSION)
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
#endif

}

half4 GetStreamColor(half4 color, half streamMask, half4 streamTex, half streamFactor, half streamColorFactor, half streamTex)
{
    streamTex = lerp(half4(streamTex.r, streamTex.r, streamTex.r), streamTex, streamColorFactor);

    half luminance = dot(color.rgb, half3(0.2126729f, 0.7151522f, 0.0721f));
    half3 luminanceColor = half3(luminance,l uminance, luminance);
    half4 saturationColor = half4( lerp(luminanceColor, color.rgb, streamFactor), 1 );
    half4 streamColor = lerp(color, saturationColor, streamTex);
    return lerp(color, streamColor, streamMask);
}

#endif