#ifndef MYENGINE_URP_PARTICLE_LIT_BASE
#define MYENGINE_URP_PARTICLE_LIT_BASE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

//#include "./ParticleUIClip.hlsl"
#include "../Skybox/TOD_Base.hlsl"
#include "../Base/Includes/MyEngine_Fog.hlsl"
#include "../Base/Includes/MyEngine_Common.hlsl"
#include "../Base/Includes/MyEngine_Wind.hlsl"

CBUFFER_START(UnityPerMaterial)
    half _Alpha;
    half _ColorFactor;
    half4 _Color;
    half4 _MainTex_ST;
  
    half _ProjectionPositionOffsetZ;
    half _Poser;
    half _Gray;
    half _BlackAlpha;
    half _Fog;
 
// Metallic
    half _Metallic0;
    half _Metallic;

// Gloss
    half _Gloss0;
    half _Gloss;

// ALPHATEST_ON
    half _AlphaClip;
    half _Cutoff;

// MAINTEX_UV_SCROLL
    half _MainOffsetX;
    half _MainOffsetY;

// NORMAL
    half _NormalOffsetU;
	half _NormalOffsetV;
    half _NormalScale;
    float4 _NormalTex_ST;

// NORMAL Mask
	half _NormalMaskOffsetU;
	half _NormalMaskOffsetV;
    half _NormalMaskOffset;
    float4 _NormalMaskTex_ST;

// DISSOLVE
    half _Dissolve;   
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

CBUFFER_END

TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);

#if defined(DISSOLVE)
    TEXTURE2D(_DissolveMap);        SAMPLER(sampler_DissolveMap);
#endif

#if defined(_NORMALMAP)
    TEXTURE2D(_NormalTex);        SAMPLER(sampler_NormalTex);
#endif

#if defined(NORMALMASK)
    TEXTURE2D(_NormalMaskTex);        SAMPLER(sampler_NormalMaskTex);
#endif


struct Attributes
{
    float4      positionOS          :   POSITION;
    half4       color               :   COLOR;
    float4      normalOS            :   NORMAL;
    float4      tangentOS           :   TANGENT;
    float2      uv                  :   TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    half4 color : COLOR;
    float2 uv : TEXCOORD0;
    half3 normalWS : TEXCOORD1;
    half3 positionWS : TEXCOORD2;

#if defined(_NORMALMAP) && defined(_USE_NORMALMAP)
    half4 normalWS   :   TEXCOORD3;
    half4 tangentWS  :   TEXCOORD4;
    half4 bitangentWS  :   TEXCOORD5;
#else
    half3 normalWS      : TEXCOORD3;
    half3 viewDirWS      : TEXCOORD4;
#endif

#if defined(DISSOLVE)
    half2       dissolve            :   TEXCOORD6;
    half4       dissolveUVAndValue  :   TEXCOORD7;
#endif

#if defined(DECAL) || defined(_DECAL_ON)
    float4      viewRayOS          :   TEXCOORD10;
    float3      camPosOS           :   TEXCOORD11;
#endif

#if defined(DECAL) || defined(_DECAL_ON)|| defined(PARTICLEDISTORTION)
    float4      screenUV           :   TEXCOORD12;
#endif

#if defined(_EFFECTFOG_ON)
    half2        fogAtten          :   TEXCOORD15;
#endif

};



half3 GrayColor(half3 color, half gray)
{
    float colorGray = dot(color, float3(0.299, 0.587, 0.144));
    return lerp(color, colorGray, gray);
}


Varyings vert(Attributes input)
{
        Varyings output = (Varyings)0;

        float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        float4 positionCS = TransformWorldToHClip(positionWS);

        VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
        VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

        half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
        half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

#if UNITY_REVERSED_Z
        float ZHClipOffset = positionCS.z + _ProjectionPositionOffsetZ / positionCS.w;
        positionCS.z = ZHClipOffset;
#else
        float ZHClipOffset = positionCS.z - _ProjectionPositionOffsetZ / positionCS.w;
        positionCS.z = ZHClipOffset;
#endif

        output.positionCS = positionCS;
        output.color = input.color * _Color ;
        output.color.rgb *= max(_ColorFactor,0);
#if defined(_UV_RADIAL_ON)
        output.uv = input.uv;        
#elif defined(MAINTEX_UV_SCROLL)
        output.uv = frac(float2(_MainOffsetX, _MainOffsetY) * _Time.y);
#elif defined(FRAMES)
        float time = floor(_Time.y * _Speed);
        float row = floor(time / _ColNum);
        float colum = time - row * _ColNum;

        half2 framesUV = float2(input.uv.x / _ColNum, input.uv.y / _RowNum);

        framesUV.x += colum / _ColNum;
        framesUV.y += row / _RowNum;

        output.uv = TRANSFORM_TEX(framesUV, _MainTex);        
#else 
        output.uv = TRANSFORM_TEX(input.uv, _MainTex);
#endif


#if defined(DECAL)
        float4 positionVS = mul(UNITY_MATRIX_MV, input.positionOS); //转相机空间
        float3 viewRayVS = positionVS.xyz;                          
        output.viewRayOS.w = positionVS.z;                    //记录相机空间深度
        float4x4 ViewToObjectMatrix = mul( GetWorldToObjectMatrix(), UNITY_MATRIX_I_V );
        output.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, -viewRayVS).xyz;
        output.camPosOS = ViewToObjectMatrix._m03_m13_m23;      
#endif

#if defined(DECAL) || defined(PARTICLEDISTORTION)
        output.screenUV = ComputeScreenPos(output.positionCS);
#endif

#if defined(_EFFECTFOG_ON)
        output.fogAtten = ComputeFogAtten(positionWS) * _Fog;
#endif

#if defined(_NORMALMAP)
        output.normalUV = TRANSFORM_TEX(input.uv, _NormalTex) + frac(float2(_NormalOffsetX, _NormalOffsetY) * _Time.y);
#endif

#if defined(NORMALMASK)
        output.normalMaskUV = TRANSFORM_TEX(input.uv, _NormalMaskTex) + frac(float2(_NormalMaskOffsetX, _NormalMaskOffsetY) * _Time.y);
#endif

    return output;
}

    half4 frag(Varyings input) : SV_Target
    {
       
        #if defined(DECAL)
            input.viewRayOS.xyz *= rcp(input.viewRayOS.w);
            float2 uv = input.screenUV.xy / input.screenUV.w;
            float rawDepth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, uv, 0);
            float depth = LinearEyeDepth(rawDepth, _ZBufferParams);
            float3 positionOS = input.camPosOS + input.viewRayOS.xyz * depth;
            clip(float3(0.5, 0.5, 0.5) - abs(positionOS.xyz));

            #if defined(_UV_RADIAL_ON)
                input.uv = positionOS.xz + float2(0.5,0.5);
            #else
                input.uv = TRANSFORM_TEX(positionOS.xz + float2(0.5, 0.5), _MainTex) + frac(float2(_MainOffsetX,_MainOffsetY) * _Time.y);
            #endif

            #if defined(_UV_ROTATE_ON)
                input.uv = RotateUV(input.uv, _UVRotate);
            #endif

            #if defined(_UV_RADIAL_ON)
                float r = 1;
                input.uv = RadialUV(input.uv, r, _MainTex_ST);
                half cornerAlpha = step(r,1);
            #endif

            #if defined(MASK)
                input.maskUV = input.uv * _MaskTex_ST.xy + _MaskTex_ST.zw + frac(half2(_MaskOffsetX, _MaskOffsetY) * _Time.y );
            #endif

            #if defined(NOISE)
                #if defined(NOISEMASK)
                    input.distortionUV.xy = TRANSFORM_TEX(input.uv, _DistortionMap) + frac(float2(_DistortionSpeed.x, _DistortionSpeed.y) * _Time.y);
                    input.distortionUV.zw = input.uv * _DistortionSpeed.zw;
                    input.distortionMaskUV = TRANSFORM_TEX(input.uv, _DistortionMaskMap) + frac( float2( _DistortionMaskU, _DistortionMaskV ) * _Time.y );
                #else
                    input.distortionUV.xy = TRANSFORM_TEX(input.uv, _DistortionMap) + frac(float2(_DistortionOffsetX, _DistortionOffsetY) * _Time.y);
                    input.distortionUV.zw = 1;
                #endif
            #endif

            #if defined(DISSOLVE)
                    input.dissolveUVAndValue.xy = input.uv * _DissolveMap_ST.xy + _DissolveMap_ST.zw  + frac(float2(_DissolveOffsetX, _DissolveOffsetY) * _Time.y);
            #endif
            
            #if defined(DISSOLVEMASK)
                    input.dissolveUVAndValue.zw = input.uv * _DissolveMaskMap_ST.xy + _DissolveMaskMap_ST.zw  + frac(float2(_DissolveMaskMapUSpeed, _DissolveMaskMapVSpeed) * _Time.y);
            #endif

            #if defined( WARNINGARROW)
                input.attributesUV = positionOS.xz + float2 (0.5,0.5);
                input.flowUV = float2(input.attributesUV.x, input.attributesUV.y + ( 1 - _WarningDuration));
            #endif

            #if defined(_NORMALMAP)
                input.normalUV = TRANSFORM_TEX(input.uv, _NormalTex) + frac(float2(_NormalOffsetX, _NormalOffsetY) * _Time.y);
            #endif

            #if defined(NORMALMASK)
                input.normalMaskUV = TRANSFORM_TEX(input.uv, _NormalMaskTex) + frac(float2(_NormalMaskOffsetX, _NormalMaskOffsetY) * _Time.y);
            #endif

        #else

            #if defined(_UV_ROTATE_ON)
                input.uv = RotateUV(input.uv, _UVRotate);
            #endif

            #if defined(_UV_RADIAL_ON)
                float r = 1;
                input.uv = RadialUV(input.uv, r, _MainTex_ST);
                half cornerAlpha = step(r,1);
            #endif
            
        #endif

        #if defined(NOISE)
            half3 distortionMap = SAMPLE_TEXTURE2D(_DistortionMap, sampler_DistortionMap, input.distortionUV.xy).rgb;
            half2 distortionXY = distortionMap.rg * distortionMap.b * input.distortionUV.zw;
            #if defined(NOISEMASK)
                half3 distortionMaskMap = SAMPLE_TEXTURE2D(_DistortionMaskMap, sampler_DistortionMaskMap, input.distortionMaskUV.xy).rgb;
                distortionXY *= distortionMaskMap.rg * distortionMaskMap.b;
            #endif

            input.uv += distortionXY;

            #if defined(DISSOLVE)
                input.dissolveUVAndValue.xy += distortionXY;
            #endif

            #if defined(DISSOLVEMASK)
                input.dissolveUVAndValue.xy += distortionXY;
            #endif
        #endif

        half4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
        
        #if defined(BLACKALPHA)
            mainTexColor.a = (mainTexColor.r + mainTexColor.g + mainTexColor.b) * _BlackAlpha + ( 1 - _BlackAlpha) * mainTexColor.a ;           
        #endif

        #if defined(POWCOLOR)
            mainTexColor.rgb = pow(mainTexColor.rgb, _Poser.xxx).rgb;
        #endif

        #if defined(GRAYCOLOR)
            mainTexColor.rgb = GrayColor(mainTexColor.rgb, _Gray);
        #endif

        half4 col = input.color * mainTexColor;

        #if defined(WARINGARROW)
            half warningArrowMask = smoothstep(0, 0.3, input.attributesUV.y);
            half4 mainCol = mainTexColor.r * warningArrowMask * input.color;

            half4 flowTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.flowUV);
            half4 flowCol = flowTexColor.g * mainTexColor.b * warningArrowMask * _FlowColor;
            col = mainCol + flowCol;
        #endif

        #if defined(WARNINGSECTOR)
            #if _INDICATOR_ON
                return mainTexColor.b * 0.6 * input.color;
            #endif
            float2 centerUV = (input.uv *2 - 1);
            float atan2UV = 1 - abs(atan2(centerUV.y, centerUV.x) / 3.14);
            half sector  = lerp(1.0, 1.0 - ceil(atan2UV - _WarningAngle * 0.002777778), _WarningSector);
            half sectorBig =lerp(1.0, 1.0 - ceil(atan2UV - (_WarningAngle + _WarningOutline) * 0.002777778), _WarningSector);
            half outline = ( sectorBig - sector ) * mainTexColor.g * _WarningOutlineAlpha;

            half needOutline = 1 - step(359, _WarningAngle);
            outline *= needOutline;
            col = mainTexColor.r * input.color * sector + outline * input.color;

            half flowCircleInner = smoothstep(_WarningDuration - _WarningFlowFade, _WarningDuration, length(centerUV));
            half flowCircleMask = step(length(centerUV), _WarningDuration);
            half4 flow = flowCircleInner * flowCircleMask * _WarningFlowColor * mainTexColor.g * sector;

            col += flow;
            return col;            
        #endif

        #if defined(_UV_RADIAL_ON)
            col.a *= cornerAlpha;
        #endif

        #if defined(MASK)
            half4 maskTexColor = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.maskUV);
            col.a = col.a * maskTexColor.r;
        #endif

        #if defined(PARTICLEDISTORTION)
            float2 screenUV = input.screenUV.xy / input.screenUV.w;
            screenUV = screenUV + mainTexColor.rg * maskTexColor.rg * mainTexColor.a * _DistortionIntensity;
            col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_LinearClamp,screenUV);
            col.a = input.color.a * mainTexColor.a * maskTexColor.a;
        #endif

        #if defined(_AMBIENTLIGHT_ON)
            Light light = GetMainLight();
            col.rgb = lerp(col.rgb,col.rgb * light.color.rgb * TOD_AmbientColor, _AmbientingIntensity);
        #endif

        #if defined(DETAILTEX)
            half4 detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, input.detailUV);
            col *= detailTex;
        #endif

        #if defined(_RIMLIGHTIN_ON)
            _RimInnerColor *= _RimInnerFactor;
            _RimOuterColor *= _RimOuterColorFactor;
            col = RimLighting(col, input.NdotV, _RimInnerColor , _RimOuterColor, _RimOuterTickness, _RimIntensity, _RimRadius, _RimLightMode, _RimAlpha);
        #endif

        #if defined(_NORMALMAP)
            output.normalUV = TRANSFORM_TEX(input.uv, _NormalTex) + frac(float2(_NormalOffsetX, _NormalOffsetY) * _Time.y);
            SAMPLE_TEXTURE2D(_NormalTex);
        #endif

        #if defined(NORMALMASK)
            output.normalMaskUV = TRANSFORM_TEX(input.uv, _NormalMaskTex) + frac(float2(_NormalMaskOffsetX, _NormalMaskOffsetY) * _Time.y);
        #endif


        #if defined(DISSOLVE)
            half2 dissolveMap = SAMPLE_TEXTURE2D(_DissolveMap, sampler_DissolveMap, input.dissolveUVAndValue.xy).rg;
            half dissolveMapValue = dissolveMap.r;
            #if defined(DISSOLVEMASK)
                half dissolveMapMaskR = SAMPLE_TEXTURE2D(_DissolveMaskMap, sampler_DissolveMaskMap, input.dissolveUVAndValue.zw).r;
                dissolveMapValue *= dissolveMapMaskR;
            #endif

            half dissolution = 1 - dissolveMapValue;
            half threshold = input.dissolve.x - dissolution;
            half alpha = smoothstep ( -_EdgeWidth,  0, threshold);
            col.a = col.a * alpha * input.dissolve.y;
            _EdgeWidthInner = _EdgeWidthInner + _EdgeWidthMid;
            half weight = smoothstep( _EdgeWidthMid, _EdgeWidthInner, threshold);
            half3 edgeColor = (col.rgb + _EdgeColor.rgb * _EdgeColorFactor) * (1 - _EdgeBlack) + (col.rgb * _EdgeColor.rgb * _EdgeColorFactor) * _EdgeBlack;
            col.rgb = lerp(col.rgb, edgeColor, (1-weight) * _EdgeColor.a);
        #endif

        #if defined(UIMODE_ON)
            if(_ClipRect.z > 0.001|| _ClipRect.w > 0.001)
            {
                col.a *= UnityGet2DClipping(input.worldPos.xy, _ClipRect);
            }
        #endif


        #if defined(_SOFTPARTICLES_ON)
                float4 projectedPosition = input.projectedPosition;
                col.a *= SoftParticles (_SoftParticleFadeParams.x, _SoftParticleFadeParams.y,projectedPosition);
        #endif

        col.a = saturate(col.a * _Alpha);

        #if defined(_ALPHATEST_ON)
            clip(col.a - _Cutoff);
        #endif

        #if defined(_EFFECTFOG_ON)
                col.rgb = ApplyFog(col.rgb, input.fogAtten) * col.a;
        #endif

        return col;
    }


   
#endif