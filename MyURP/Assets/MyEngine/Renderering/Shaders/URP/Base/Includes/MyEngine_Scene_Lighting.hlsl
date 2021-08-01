#ifndef MYENGINE_URP_SCENE_LIGHTING_INCLUDED
#define MYENGINE_URP_SCENE_LIGHTING_INCLUDED

#include "./MyEngine_Lighting.hlsl"

half _GlobalDiffuseWrap;
half _GlobalDiffuseMultiplier;

half _GlobalFoliageDiffuseWrap;
half _GlobalFoliageDiffuseWrapMultiplier;

half _GlobalGrassDiffuseWrap;
half _GlobalGrassDiffuseWrapMultiplier;
half3 _GlobalGrassAmbientColor;

float _FoliageShadowBiasOffset;
float _GrassShadowBiasOffset;

int _DebugType;

TEXTURE2D(_ReflectionBlruRT); SAMPLER(sampler_ReflectionBlurRT);

TEXTURECUBE(_GlobalTODCubemap);    SAMPLE(sampler__GlobalTODCubemap);
half4 _GlobalTODCubemap_HDR;

float3 ApplySceneShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection, float shadowBiasOffset)
{
    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y;

    positionWS = lightDirection * (_ShadowBias.xxx + shadowBiasOffset.xxx) + positionWS;
    positionWS = normalWS * scale.xxx + positionWS;
    return positionWS;
}

half3 GlossyEnvironmentReflectionBase(half3 reflectVector, half perceptualRoughness, half occlusion, half3 reflectionParam)
{
    #if !defined(_ENVIROMEENTREFLECTIONS_OFF)
        half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
        half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, Samplerunity_SpecCube0, reflectVector, mip);
        
        #if !defined(UNITY_USE_NATIVE_HDR)
            half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
        #else
            half3 irradiance = encodedIrradiance.rgb;
        #endif

        #if defined(_REFLECTIONTYPE_REALTIME)
            half3 finalReflection = SAMPLE_TEXTURE2D_LOD(_ReflectionBlurRT, sampler_ReflectionBlurRT, reflectionParam.xy, mip).rgb;
            irradiance = lerp(irradiance, finalReflection,reflectionParam.z);
        #endif

        #if defined(_REFLECTIONTYPE_SSR)
            half3 finalReflection = SAMPLE_TEXTURE2D_LOD(_ReflectionBlurRT, sampler_ReflectionBlurRT, reflectionParam.xy, mip).rgb;
            irradiance = lerp(irradiance, finalReflection,reflectionParam.z);
        #endif

        return irradiance * occlusion;

    #endif

    return _GlossyEnvironmentColor.rgb * occlusion;
}

half3 GlobalIlluminationBase(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS, half3 reflectionParam, half4 ssr)
{
#if defined(_ENV_REFLECTION)
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflectionBase(reflectVector, brdfData.perceptualRoughness, occlusion, reflectionParam, ssr);

    return EnvironmentDRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
#else

    half3 indirectDiffuse = bakedGI * occlusion;
    return indirectDiffuse * brdfData.diffuse;

#endif
}

half3 GlobalIlluminationWithoutIBL(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS,half3 viewDirectionWS)
{
    half3 indirectDiffuse = bakedGI * occlusion;
    return indirectDiffuse * brdfData.diffuse;
}

half4 UniversalTranslucentFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half4 translucency,
    half diffuseWrap, half diffuseWrapMultiplier, half lightmapShadow = 1)
{
    BRDFData brdfData;
    InitializedBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined(LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, InputData.positionWS, shadowMask);
    mainLight.shadowAttenuation = min(mainLight.shadowAttenuation, lightmapShadow);
    mainLight.shadowAttenuation = ApplyMicroShadow(occlusion, inputData.normalWS, mainLight.direction, mainLight.shadowAttenuation);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIlluminationWithoutIBL(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    half NdotL = saturate( (dot(inputData.normalWS, mainLight.direction) + diffuseWrap) * diffuseWrapMultiplier );
    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

#if defined(_TRANSLUCENCY_LIT);
    half translucencyShadowAttenuation = min(mainLight.shadowAttenuation, occlusion);
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot(transLightDir, -inputData.viewDirectionWS);
    transDot = exp2(saturate(transDot) * transPower - transPower);
    color += brdfData.diffuse * transDot * (1.0 - NdotL) * mainLight.color * lerp(1.0h, translucencyShadowAttenuation, translucency.z) * translucency.x * 4;
#endif

    color.rgb = ApplyBrightness(color.rgb);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; ++i )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif  

            half NdotL  = saturate((dot(inputData.normalWS, light.direction) + diffuseWarp) * diffuseWrapMultiplier);
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
        }
    #endif

    #if defined(_ADDINATIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += ApplyBrightness(emission);

    return half4(color, alpha);
}

half4 UniversalWarppedFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha)
{
    BRDFData brdfData;
    InitializedBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined(LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, InputData.positionWS, shadowMask);    
    mainLight.shadowAttenuation = ApplyMicroShadow(occlusion, inputData.normalWS, mainLight.direction, mainLight.shadowAttenuation);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    half NdotL = saturate( (dot(inputData.normalWS, mainLight.direction) + diffuseWrap) * diffuseWrapMultiplier );

    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    color.rgb = ApplyBrightness(color.rgb);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; ++i )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif  

            half NdotL  = saturate((dot(inputData.normalWS, light.direction) + diffuseWarp) * diffuseWrapMultiplier);
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
        }
    #endif

    #if defined(_ADDINATIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if defined(_EMISSION)
        color += ApplyBrightness(emission);
    #endif
    
    return half4(color, alpha);
}

half4 UniversalWithoutIBLFragmentPBR(InputData inputData, half albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha)
{
    BRDFData brdfData;
    InitializedBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined(LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, InputData.positionWS, shadowMask);    
    mainLight.shadowAttenuation = ApplyMicroShadow(occlusion, inputData.normalWS, mainLight.direction, mainLight.shadowAttenuation);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIlluminationWithoutIBL(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    half NdotL = saturate( (dot(inputData.normalWS, mainLight.direction) + diffuseWrap) * diffuseWrapMultiplier );

    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    color.rgb = ApplyBrightness(color.rgb);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; ++i )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif  

            half NdotL  = saturate((dot(inputData.normalWS, light.direction) + diffuseWarp) * diffuseWrapMultiplier);
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
        }
    #endif

    #if defined(_ADDINATIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if defined(_EMISSION)
        color += ApplyBrightness(emission);
    #endif
    
    return half4(color, alpha);
}

half4 UniversalBlurFragmentPBR(InputData inputData, half albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half3 backgroundColor, half transmittance)
{
    BRDFData brdfData;
    InitializedBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined(LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight();
    mainLight.direction = inputData.viewDirectionWS;

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIlluminationWithoutIBL(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    half NdotL = saturate( (dot(inputData.normalWS, mainLight.direction) + diffuseWrap) * diffuseWrapMultiplier );

    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    color = lerp(color, backgroundColor, transmittance);

    color.rgb = ApplyBrightness(color.rgb);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; ++i )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif  

            half NdotL  = saturate((dot(inputData.normalWS, light.direction) + _GlobalDiffuseWrap) * _GlobalDiffuseWrapMultiplier);
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
        }
    #endif

    #if defined(_ADDINATIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if defined(_EMISSION)
        color += ApplyBrightness(emission);
    #endif
    
    return half4(color, alpha);
}


half4 UniversalComplexFragmentPBR(InputData inputData, half albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half3 reflectionParam, half4 ssr, half3 lightDecalColor)
{
    BRDFData brdfData;
    InitializedBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined(LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, InputData.positionWS, shadowMask);    
    mainLight.shadowAttenuation = ApplyMicroShadow(occlusion, inputData.normalWS, mainLight.direction, mainLight.shadowAttenuation);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

#if defined(_LIGHTDECAL_ON)
    mainLight.color *= lightDecalColor;
#endif

    half3 color = GlobalIlluminationBase(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    half NdotL = saturate( (dot(inputData.normalWS, mainLight.direction) + diffuseWrap) * diffuseWrapMultiplier );

    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    color.rgb = ApplyBrightness(color.rgb);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; ++i )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif  

            half NdotL  = saturate((dot(inputData.normalWS, light.direction) + diffuseWarp) * diffuseWrapMultiplier);
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
        }
    #endif

    #if defined(_ADDINATIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if defined(_EMISSION)
        color += ApplyBrightness(emission);
    #endif
    
    return half4(color, alpha);
}

#endif