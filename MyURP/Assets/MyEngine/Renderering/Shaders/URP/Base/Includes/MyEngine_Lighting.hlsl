#ifndef MYENGINE_URP_LIGHTING_INCLUDED
#define MYENGINE_URP_LIGHTING_INCLUDED

#include "../../SkyBox/TOD_Base.hlsl"
#include "../../SkyBox/TOD_Clouds.hlsl"
#include "./MyEngine_Common.hlsl"

half3 _ShadowColor;

half3 LightingPhysicallyBaseWrapped(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half distanceAttenuation, half shadowAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    half3 radiance = lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation * NdotL;
    return DirectBRDF(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}

half3 LightingPhysicallyBasedWrapped(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    return LightingPhysicallyBaseWarpped(brdfData, light.color, light.direction, light.distanceAttenuation, light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
}

#endif