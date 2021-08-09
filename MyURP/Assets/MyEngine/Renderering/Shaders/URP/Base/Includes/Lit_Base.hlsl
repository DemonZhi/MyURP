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
#include "./MyEngine_Wind.hlsl"
#include "./MyEngine_Wet.hlsl"

#undef BUMP_SACLE_NOT_SUPPORTED

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _EmissionColor;
half _EmissionIntensity;
half _Cutoff;
half _MetallicScale;
half _RoughnessScale;
CBUFFER_END

TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetallicGlossMap);      SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_CubemapEmissionCubemap);      SAMPLER(sampler_CubemapEmissionCubemap);

struct Attributes
{
    float4      positionOS          :   POSITION;
    float4      normalOS            :   NORMAL;
    float4      tangentOS            :   TANGENT;
    half4       color               :   COLOR;
    float2      texcoord            :   TEXCOORD0;    
    float2      lightmapUV            :   TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
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
    float4 positionCS :  SV_POSITION;
    #if defined(_SGENGINE_DEBUG)
        half4 vertexColor   : COLOR;
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

#endif