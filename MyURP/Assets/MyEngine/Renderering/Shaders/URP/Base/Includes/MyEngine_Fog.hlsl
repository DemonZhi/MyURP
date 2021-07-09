#ifndef MYENGINE_URP_FOG_INCLUDE
#define MYENGINE_URP_FOG_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "./MyEngine_Common.hlsl"

half _FogEndDistance;
half _FogSolidDistance;
half _FogStrength;
half4 _FogColor;
half _FogHeight;
half _FogHeightFalloff;
half _FogDensity;
half _FogAmbient;
half4 _FogColorFade;
half _FogHeightStartDistance;
half _FogHeightMinOpacity;

// code from Unreal

float CalculateLineIntegralShared(float fogHeightFalloff, float rayDirectionY, float fogDensity)
{
    float falloff = max( -127.0f, fogHeightFalloff * rayDirectionY);
    float lineIntegral = ( 1.0f - exp2(-falloff)) / falloff;
    return max(fogDensity * lineIntegral, 0);
}

float2 ComputeFogAtten(float3 worldPos)
{
    float2 fogAtten;

    float3 cameraToReceiver = _WorldSpaceCameraPos.xyz - worldPos;
    float cameraToReceiverLength = length(cameraToReceiver);
    
    float distanceFadeFactor = (_FogEndDistance - cameraToReceiverLength) * _FogSolidDistance;
    float distanceFade = 1.0 - clamp( distanceFadeFactor, 0.0, 1.0 );

    fogAtten.x = distanceFade * _FogStrength;

    float heightFogDensity = _FogDensity * exp2(_FogHeightFalloff * (_FogHeight - worldPos.y));
    float exponentialHeightLineIntegral = CalculateLineIntegralShared(_FogHeightFalloff, cameraToReceiver.y, heightFogDensity) * cameraToReceiverLength;
    exponentialHeightLineIntegral *= max(cameraToReceiverLength - _FogHeightStartDistance, 0 );
    float expHeightFogFactor = max(saturate( exp2(-exponentialHeightLineIntegral)),_FogHeightMinOpacity);

    fogAtten.y = 1 - expHeightFogFactor;

    return fogAtten;
}

half3 ApplyFog(half3 finalColor, half2 fogAtten)
{
    Light mainLight = GetMainLight();
    half3 fogColor = _FogColor.rgb * ( mainLight.color + max(finalColor - half3(1,1,1) , 0) + _FogAmbient );

    finalColor = lerp(finalColor , fogColor * _GlobalBrightness, fogAtten.y);
    finalColor = lerp(finalColor , _FogColorFade.rgb * _GlobalBrightness, fogAtten.x);

    return finalColor;
}


#endif