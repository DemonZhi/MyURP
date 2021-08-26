#ifndef MYENGINE_URP_CLOTHLIT_BASE
#define MYENGINE_URP_CLOTHLIT_BASE

// URP
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

// MyEngine
#include "../../Base/Includes/MyEngine_Common.hlsl"
#include "../../Base/Includes/MyEngine_Fog.hlsl"
#include "../../Base/Includes/MyEngine_Role_Lighting.hlsl"
#include "../../Base/Includes/MyEngine_Wet.hlsl"


#undef BUMP_SACLE_NOT_SUPPORTED

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _EmissionColor;
half _EmissionIntensity;

half _Cutoff;
half _MetallicScale;
half _RoughnessScale;

half _FresnelScale;
half4 _RimOuterColor;
half4 _RimInnerColor;
half _RimOuterThickness;
half _RimIntensity;

half _DissolveCutoff;
half4 _DissolveEdgeColor;
half _DissolveEdgeWidth;
float _DissolveNoiseMapTiling;
half _DissolveNoiseStrength;

half4 _DetailParam;
half3 _DetailColor;

half _SilkDetailUVScale;
half _SilkSpec01Shift;
half _SilkSpec01Range;
half3 _SilkSpec01Color;
half _SilkSpec02Shift;
half _SilkSpec02Range;
half3 _SilkSpec02Color;

CBUFFER_END



TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
TEXTURE2D(_MetallicGlossMap);      SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SkinLUT);      SAMPLER(sampler_SkinLUT);

TEXTURE2D(_DissolveNoiseMap);      SAMPLER(sampler_DissolveNoiseMap);
TEXTURE2D(_DetailNormalMap);      SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_SilkDetailMap);      SAMPLER(sampler_SilkDetailMap);
TEXTURE2D(_FlowLightMap);      SAMPLER(sampler_FlowLightMap);
TEXTURE2D(_FlowLightMaskMap);      SAMPLER(sampler_FlowLightMaskMap);
TEXTURE2D(_DetailMap);      SAMPLER(sampler_FlowLightMaskMap);


struct Attributes
{
    float4      positionOS          :   POSITION;
    float4      normalOS            :   NORMAL;
    float4      tangentOS           :   TANGENT;    
    float2      texcoord            :   TEXCOORD0;    
    float2      lightmapUV            :   TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

    float3 positionWS : TEXCOORD2;

    #if defined(_NORMALMAP)
        half4 normalWS : TEXCOORD3;
        half4 tangentWS : TEXCOORD4;
        half4 bitangentWS : TEXCOORD5;
    #else
        half3 normalWS : TEXCOORD3;
        half3 viewDirWS: TEXCOORD4;
        half3 bitangentWS : TEXCOORD5;
    #endif

    half4 fogFactorAndVertexLight   :   TEXCOORD6; // x fogFactor, yzw: vertexLight

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        float4 shadowCoord  :   TEXCOORD7;
    #endif

    float2 fogAtten :   TEXCOORD8;
    


    #if defined(_FLOWLIGHTING_ON) 
        float2 FlowLightOffsetUV  :   TEXCOORD9;
        float2 FlowLightMaskOffsetUV  :   TEXCOORD9;
    #endif

    float4 positionCS :     SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct SurfaceDescription
{
    half3 albedo;
    half alpha;
    half3   normalTS;
    half3   emission;
    half    metallic;
    half3   specular;
    half    smoothness;
    half    occlusion;
    half    fresnel;
    #if defined(_SILK_ON)
        half silkMask;
        half silkSpecShift;
    #endif
};

inline void InitializeStandardLitSurfaceData(Varyings input, out SurfaceDescription outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    outSurfaceData.smoothness = saturate(1 - specGloss.r * _RoughnessScale);
    outSurfaceData.fresnel = _FresnelScale;
    outSurfaceData.metallic = saturate(specGloss.g * _MetallicScale);
    
    half4 normalColor = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);    
    outSurfaceData.normalTS = MyUnpackNormalRG(normalColor.rg);
    outSurfaceData.occlusion = normalColor.b;

    #if defined(_EMISSION)
        outSurfaceData.emission = SampleEmission(input.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)) * _EmissionIntensity;        
    #else
        outSurfaceData.emission = half3(0, 0, 0);
    #endif

 #if defined(_SILK_ON)
    outSurfaceData.silkMask = step(0.8, specGloss.a);
    outSurfaceData.silkSpecShift = SAMPLE_TEXTURE2D(_SilkDetailMap, sampler_SilkDetailMap, input.uv * _SilkDetailUVScale);
 #endif

 #if defined(_DETAILMAP_ON)
    half clothMask = specGloss.b;
    half4 detailColor = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, input.uv * _DetailParam.z);
    half3 normalTS = MyUnpackNormalScale(half4(detailColor.rgb, 1), _DetailParam.y);
    outSurfaceData.normalTS.xy += normalTS.xy * clothMask * (1 - detailColor.a);
    outSurfaceData.smoothness = lerp(outSurfaceData.smoothness, _DetailParam.x, detailColor.a * clothMask);
    outSurfaceData.albedo = lerp(outSurfaceData.albedo, _DetailColor.rgb, detailColor.a * clothMask * _DetailParam.w);
#endif

}

void InitializeInputData(Varyings input, half3 normalTS, half facing, out InputData inputData)
{
    inputData = (InputData)0;
    inputData.positionWS = input.positionWS;

    #if defined(_NORMALMAP)
        half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
        half3x3 ToW = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
        normalTS.z = facing;
        inputData.normalWS = TransformTangentToWorld(normalTS, ToW);
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
  
#if defined(_SCREEN_SPACE_OCCLUSION)
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
#endif

}

Varyings ClothVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    half3 viewDirWS =  GetCameraPositionWS() -  vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    #if defined(_NORMALMAP) && defined(_USE_NORMALMAP)
        output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
        output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
        output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
    #else
        output.normalWS = SafeNormalize_Half3(normalInput.normalWS);
        output.bitangentWS = normalInput.bitangentWS;
        output.viewDirWS = viewDirWS;
    #endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(0, vertexLight);
    output.positionWS = vertexInput.positionWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        output.shadowCoord = GetShadowCoord(vertexInput);
    #endif

    output.fogAtten = ComputeFogAtten(vertexInput.positionWS);
    output.positionCS = vertexInput.positionCS;
    return output;
}

half4 ClothFragment(Varyings input, half facing : VFACE) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;
    InitializeStandardLitSurfaceData(input, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, facing, inputData);

    #if defined(_MYENGINE_WET)
        WetRoleBRDF(surfaceData.metallic, surfaceData.normalWS, 0, surfaceData.albedo, surfaceData.smoothness);
    #endif
    
    #if defined(_DISSOLVE_ON)
        float2 dissolveNoiseUV = input.uv * _DissolveNoiseMapTiling;
        half dissolveThreshold = DissolveClip(inputData.normalWS, inputData.viewDirectionWS, _DissolveCutoff, TEXTURE2D_ARGS(_DissolveNoiseMap, sampler_DissolveNoiseMap), dissolveNoiseUV, _DissolveNoiseStrength );        
    #endif
    
    #if defined(_SILK_ON)
        Light mainLight = GetMainLight(inputData.shadowCoord);  
        surfaceData.albedo += AnisoSpecular(mainLight.direction, mainLight.color, inputData.viewDirectionWS, inputData.normalWS,
        input.bitangentWS, surfaceData.silkSpecShift, surfaceData.silkMask, _SilkSpec01Shift, _SilkSpec01Range, _SilkSpec02Shift, _SilkSpec02Range,_SilkSpec01Color,_SilkSpec02Color);
    #endif

    half4 Color = UniversalClothFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion,
    surfaceData.emission, surfaceData.alpha, surfaceData.fresnel);

    #if defined(_RINLIGHTING_ON)
        color.rgb = RimLighting(color.rgb, inputData.normalWS, inputData.viewDirectionWS, _RimInnerColor, _RimOuterColor, _RimOuterThickness, _RimIntensity);
    #endif

    #if defined(_DISSOLVE_ON)
        color.rgb = DissolveColoring(color.rgb, _DissolveEdgeColor, _DissolveEdgeWidth, dissolveThreshold);
    #endif

    color.rgb = ApplyFog(color.rgb, input.fogAtten);

    color.rgb = clamp(color.rgb,half3(0,0,0), half3(4,4,4));

    return color;
}

#endif