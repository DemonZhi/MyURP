#ifndef MYENGINE_URP_UI_BLURRED_BASE
#define MYENGINE_URP_UI_BLURRED_BASE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "./ParticleUIClip.hlsl"
#include "../Base/Includes/MyEngine_Fog.hlsl"
#include "../Base/Includes/MyEngine_Common.hlsl"
#include "../Base/Includes/MyEngine_Wind.hlsl"

CBUFFER_START(UnityPerMaterial)
    half _Alpha;
    half _ColorFactor;
    half4 _Color;
    half4 _MainTex_ST;
    float4 _ClipRect;
    half _ProjectionPositionOffsetZ;
    half _Poser;
    half _Gray;
    half _BlackAlpha;
    half _Fog;
    half _UVRotateEnabled;
    half _UVRotate;

// VERTEXOFFSET
    half _VertexOffsetTexU;
    half _VertexOffsetTexV;
    half4 _VertexOffsetIntensity;

// ALPHATEST_ON
    half _AlphaClip;
    half _Cutoff;

// DETAILTEX
    half4 _DetailTex_ST;
    half _DetailOffsetX;
    half _DetailOffsetY;

// MAINTEX_UV_SCROLL
    half _MainOffsetX;
    half _MainOffsetY;

// MASK
    half4 _MaskTex_ST;
    half _MaskOffsetX;
    half _MaskOffsetY;

// DISSOLVE
    half _Dissolve;
    half _DissolveSoftStep;
    half4 _DissolveMap_ST;
    half _DissolveOffsetX;
    half _DissolveOffsetY;
    half _DissolveType;
    half _DissolveWidth;

    half4 _EdgeColor;
    half _EdgeColorFactor;
    half _EdgeWidth;
    half _EdgeWidthInner;
    half _EdgeWidthMid;
    half _EdgeBlack;


// DISSOLVEMASK
    half4 DissolveMaskMap_ST;
    half _DissolveMaskMapUSpeed;
    half _DissolveMaskMapVSpeed;

// NOISE
    half _DistortionStrength;
    half _DistortionOffsetX;
    half _DistortionOffsetY;
    half4 _DistortionMap_ST;

// NOISE MASK
    half4 _DistortionMaskTex_ST;
    half _DistortionMaskU;
    half _DistortionMaskV;
    half4 _DistortionSpeed;

// FRAMES
    half _RowNum;
    half _ColNum;
    half _Index;
    half _Speed;
    half _StartIndex;
    half _EndIndex;

// SOFTPARTICLES
    float4 _SoftParticleFadeParams;

// RIMLIGHTING
    half    _RimLighting;
    half    _RimLightMode;
    half4   _RimInnerColor;
    half    _RimInnerColorFactor;
    half4   _RimOuterColor;
    half    _RimOuterColorFactor;
    half    _RimOuterTickness;
    half    _RimRadius;
    half    _RimIntensity;
    half    _RimAlpha;

// AMBIENTLIGHT
    half _AmbientingIntensity;

// WARNING ARROW SECTOR
    half4   _WarningFlowColor;
    half    _WarningFlowFade;
    half    _WarningDuration;
    half    _WarningAngle;
    half    _WarningSector;
    half    _Outline;
    half    _OutlineAlpha;

// PARTICLE WAVE
    half    _FlagWaveSpeed;
    half    _FlagWaveFrequencyScale;
    half4   _FlagWaveScale;
    half    _FlagWaveNoiseScale;
    half    _FlagWaveLengthOffset;
    half4   _FlagWaveWindScale;

CBUFFER_END

TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

#if defined(_VERTTEXOFFSET_ON) && define(PARTICLE_WAVE)
    TEXTURE2D(_VertexOffsetTex);        SAMPLER(sampler_VertexOffsetTex);
#endif

#if define(MASK)
    TEXTURE2D(_MaskTex);        SAMPLER(sampler_MaskTex);
#endif

#if define(DETAILTEX)
    TEXTURE2D(_DetailTex);        SAMPLER(sampler_DetailTex);
#endif

#if define(DISSOLVE)
    TEXTURE2D(_DissolveMap);        SAMPLER(sampler_DissolveMap);
#endif

#if define(DISSOLVEMASK)
    TEXTURE2D(_DissolveMaskMap);        SAMPLER(sampler_DissolveMaskMap);
#endif

#if define(NOISE)
    TEXTURE2D(_DistortionMap);        SAMPLER(sampler_DistortionMap);
#endif

#if define(NOISEMASK)
    TEXTURE2D(_DistortionMaskMap);        SAMPLER(sampler_DistortionMaskMap);
#endif

struct Attributes
{
    float4      positionOS          :   POSITION;
    float4      normalOS            :   NORMAL;
    half4       color               :   COLOR;
    float2      uv                  :   TEXCOORD0;    
};

struct Varyings
{
    float4      positionCS          :   SV_POSITION;
    half4       color               :   COLOR;
    float2      uv                  :   TEXCOORD0;
    half3       normalWS            :   TEXCOORD1;

#if defined(UIMODE_ON)
    float2      worldPos            :   TEXCOORD2; 
#endif 

#if defined(MASK)
    float4      maskUV              :   TEXCOORD3;
#endif

#if defined(DETAILTEX)
    float2      detailUV            :   TEXCOORD4;
#endif

#if defined(DISSOLVE)
    half2       dissolve            :   TEXCOORD5;
    half4       dissolveUVAndValue  :   TEXCOORD6;
#endif

#if defined(NOISE)
    float4      distortionUV        :   TEXCOORD7;
#endif

#if defined(NOISEMASK)
    float4      distortionMaskUV    :   TEXCOORD8;
#endif

#if defined(_SOFTPARTICLES_ON)
    float4      projectedPosition   :   TEXCOORD9;
#endif

#if defined(DECAL) || defined(_DECAL_ON)
    float4      viewRayOS          :   TEXCOORD10;
    float3      camPosOS           :   TEXCOORD11;
    float4      screenUV           :   TEXCOORD12;
#endif

#if defined(_RIMLIGHTING_ON)
    half        NdotV              :   TEXCOORD10;
#endif

#if defined(_EFFECTFOG_ON)
    half2        fogAtten          :   TEXCOORD15;
#endif

#if WARNINGARROW
    float2 attributesUV            :   TEXCOORD16;
    float2 flowUV                  :   TEXCOORD17;
#endif
}

half4 RimLighting(half4 col, half NdotV, half4 innerColor, half4 outerColor, half outerThickness, half rimIntensity, half rimRadius, half rimMode, half rimAlphaMode)
{
    half4 color = half4(0,0,0,0);

    half reverse = - rimMode + 1.0;
    half PNV = -2 * rimMode + 1.0;

    half rim = reverse - max(0, NdotV + rimRadius ) * PNV;
    rim = max(0, rim);

    half outer = rim + outerThickness;

    outer = outer * outer;
    outer = outer * outer;

    half3 finalOuterColor = outerColor.rgb * outer * rimIntensity;
    half3 finalInnerColor = innerColor.rgb * rim * rimIntensity;

    color.rbg = max(col + finalInnerColor , finalOuterColor + finalOuterColor);

    half insideAlpha = lerp(outer, 1 outerColor.a) * innerColor.a;
    color.a = (1 - rimAlphaMode) * insideAlpha * col.a + rimAlphaMode * insideAlpha;

}

half3 GrayColor(half3 color, half gray)
{
    float colorGray = dot(col, float3(0.299, 0.587, 0.144));
    return lerp(color, colorGray, gray);
}

float2 RadialUV(float2 uv, inout float r , float4 tiling)
{
    uv = uv * 2.0 - 1.0;
    r = length(uv);
    uv = float2( frac( (atan2(uv,x, uv.y)) / 6.28318548202515 ), r );
    uv.xy += tiling.zw * _Time.y;
    uv *= tiling.xy;
    return uv;
}

float2 RotateUV(float2 uv, float r)
{
    r = r * 0.017453;
    uv -= 0.5f;
    float cosAngle = cos(r);
    float sinAngle = sin(r);
    float3x3 rot = float3x3(cosAngle, -sinAngle, 0.5f, sinAngle, cosAngle, 0.5, 0, 0, 1);

    uv = mul(rot, float3(uv.xy,1));

    return uv;
}

float SoftParticle(float near, float far, float4 projection)
{
    float fade = 1;
    if(near > 0.0 || far > 0.0)
    {
        float sceneZ = LinearEyeDepth(SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(projection.xy / projection.w)).r, _ZBufferParams);
        float thisZ = LinearEyeDepth( projection.z / projection.w , _ZBufferParams);
        fade  = saturate(far * (sceneZ - near) - thisZ);
   }
   return fade;
}

Varyings vert(Attributes input)
{
    Varyings output = (Varyings)0;
#if defined(_VERTEXOFFSET_ON) || defined(PARTICLE_WAVE)
    float2 vertexOffsetUV = float2( input.uv.x + (_VertexOffsetTexU * _Time.y), input.uv.y + (_VertexOffsetTexY * _Time.y));
#endif

#if defined(_VERTEXOFFSET_ON)    
    float4 vertexOffsetColor = SAMPLE_TEXTURE2D_LOD(_VertexOffsetTex, sampler_VertexOffsetTex, vertexOffsetUV);
    vertexOffsetColor = (vertexOffsetColor - 0.5) * 2;
    input.position.xyz += (_VertexOffsetIntensity * vertexOffsetColor).rgb;
#endif

#if defined(PARTICLE_WAVE)
    float2 vertexOffsetUV
#endif

}











#endif