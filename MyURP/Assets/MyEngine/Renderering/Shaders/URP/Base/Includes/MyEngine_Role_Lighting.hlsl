#ifndef MYENGINE_URP_ROLE_LIGHTING_INCLUDED
#define MYENGINE_URP_ROLE_LIGHTING_INCLUDED

#include "./MyEngine_Lighting.hlsl"

half _RoleMainLightIntensity;
half _RoleAmbientIntensity;
half _RoleSkinAmbientIntensity;
half _RoleReflectionIntensity;
half _RoleShadowIntensity;
half _RoleEyeAdditiveSpecIntensity;

TEXTURECUBE(_RoleReflectionCubemap);    SAMPLE(sampler_RoleReflectionCubeMap);
half4 _RoleReflectionCubemap_HDR;
half4x4 _RoleReflectionCubemapRotation;

float3 DirectBRDFHighSepcular(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
    float3 halfDir = SafeNormalize_Half3(lightDirectionWS + viewDirectionWS);

    float NoH = saturate(dot(normalWS, halfDir));
    float NoL = saturate(dot(normalWS, lightDirectionWS));
    float NoV = saturate(dot(normalWS, viewDirectionWS));
    float VoH = saturate(dot(viewDirectionWS, halfDir));

    float d = (NoH * brdfData.roughness2 - NoH ) * NoH + 1;
    float D = brdfData.roughness2 / (d*d);

    float k =  brdfData.roughness * 0.5f;
    float Vis_SchlickV = NoV * ( 1 - k) + k;
    float Vis_SchlickL = NoL * ( 1 - k) + k;
    float G = 0.25 / ( Vis_SchlickV * Vis_SchlickL);

    float3 F = brdfData.specular + ( 1 - brdfData.specular) * exp2(( -5.55473 * VoH - 6.98316) * VoH);

    return D * G * F;

}

half3 StrandSpecular(half3 T, half3 H, half exponent)
{
    half TdotH = dot(T, H );
    half sintTH = sqrt(1.0 - TdotH * TdotH);
    half dirAtten = smoothstep( -1.0, 0.0, TdotH );
    return dirAtten * pow(sintTH, exponent);
}

half AnisoSpecular(half3 lightDirectionWS, half3 lightColor, half3 viewDirectionWS, half3 normalWS,
                    half3 bitangentWS, half specShift,half silkMask, half spec01Shit,
                    half spec01Range, half spec02Shif, half spec02Range, half3 spec01Color, half3 spec02Color)
                    
{
    lightColor *= _RoleMainLightIntensity;

    specShift = specShift - 0.5f;
    half3 H = SafeNormalize_Half3(lightDirectionWS + viewDirectionWS);
    half3 T = - SafeNormalize_Half3(cross(bitangentWS, normalWS));

    half3 t1 = ShiftTangent(T, normalWS, specShift + spec01Shit);
    half3 t2 = ShiftTangent(T, normalWS, specShift + spec02Shit);

    half3 specular1 = StrandSpecular(t1, H, spec01Range * 100) * spec01Color;
    half3 specular2 = StrandSpecular(t2, H, spec02Range * 100) * spec02Color;

    half NdotL = saturate(dot(normalWS, lightDirectionWS));

    half NdotSpecMask = saturate(NdotL * 0.5 + 0.5);

    half3 specular = specular1 + specular2;
    half3 anisoSpecular = max(, specular * NdotSpecMask * silkMask * saturate(lightColor));
    return anisoSpecular; 
}

half3 RimLighting(half3 finalColor, half3 normalWS, half3 viewDirectionWS, half4 innerColor, half4 outerColor, half outerThickness, half rimIntensity)
{
    half NdotV = dot(normalWS, viewDirectionWS);
    half rim = 1.002 - max(0, NdotV);

    half outer = rim + outerThickness;
    outer *= outer; 
    outer *= outer;
    half3 finalOuterColor = outerColor.rgb * outer * rimIntensity;
    half3 finalInnerColor = InnerColor.rgb * rim * rimIntensity;
    return max(finalColor + finalInnerColor, finalOuterColor + finalInnerColor);
}

half3 RimLighting(half3 finalColor, half NdotV, half4 innerColor, half4 outerColor, half outerThickness, half rimIntensity)
{
   
    half rim = 1.002 - max(0, NdotV);

    half outer = rim + outerThickness;
    outer *= outer; 
    outer *= outer;
    half3 finalOuterColor = outerColor.rgb * outer * rimIntensity;
    half3 finalInnerColor = InnerColor.rgb * rim * rimIntensity;
    return max(finalColor + finalInnerColor, finalOuterColor + finalInnerColor);
}

half DissolveClip(half3 normalWS, half3 viewDirectionWS, half dissolveCutoff, TEXTURE2D_PARAM(_DissolveNoiseMap, sampler_DissolveNoiseMap), float2 dissolveNoiseUV, half dissolveNoiseStrenght)
{
    half outer = dot(normalWS, viewDirectionWS);
    outer *= outer; 
    outer *= outer;

    half dissolveNoise = SAMPLE_TEXTURE2D(_DissolveNoiseMap, sampler_DissolveNoiseMap, dissolveNoiseUV).r;
    dissolveNoise = (dissolveNoise - 0.5) * dissolveNoiseStrenght;
    dissolveNoise = clamp(-1, 1, dissolveNoise);

    half threshold = outer + dissolveNoise - dissolveCutoff;
    clip(threshold);
    return threshold;
}

half3 DissolveColoring(half3 finalColor, half4 dissolveEdgeColor, half dissolveEdgeWidth, half dissolveThreshold)
{
    half3 finalEdgeColor = dissolveEdgeColor.rgb + finalColor;
    half weight = 1 - smoothstep(0, dissolveEdgeWidth, dissolveThreshold);
    return lerp(finalColor, finalEdgeColor, weight);
}

half3 RoleGlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
{
    reflectVector = mul(_RoleReflectionCubemapRotation, half4(reflectVector , 1)).xyz;
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedInradiance = SAMPLE_TEXTURECUBE_LOD(_RoleReflectionCubemap, sampler_RoleReflectionCubemap, reflectVector, mip);
    #if !defined(UNITY_USE_NATIVE_HDR)
        half3 irradiance = DecodeHDREnvironment(encodedInradiance, _RoleReflectionCubemap_HDR);
    #else
        half3 irradiance = encodedInradiance.rgb;
    #endif
    return irradiance * occlusion;
}

half3 GlobalIlluminationRole(BRDFData brdfData, half3 bakedGI, half occlusion , half3 normalWS, half3 viewDirectionWS, half fresnelScale, half ambientIntensity, half reflectionIntensity)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS))) * fresnelScale;

    half3 indirectDiffuse = bakedGI * occlusion * ambientIntensity;
    half3 indirectSpecular = RoleGlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion) * reflectionIntensity;

    return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}

half3 DirectBRDFSpecular(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#if !defined(_SPECULARHIGHLIGHTS_OFF)
    half3 halfDirection = SafeNormalize_Half3(lightDirectionWS + viewDirectionWS);
    float NoH = saturate(dot(normalWS, halfDirection));
    float LoH = saturate(dot(lightDirectionWS, NoH));

    half d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d*d) * max(0.1h,LoH2) * brdfData.normalizationTerm);
 

    #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
        specularTerm = specularTerm - HALF_MIN;
        specularTerm = clamp(specularTerm, 0.0, 100);
    #endif

    half3 color = specularTerm * brdfData.specular;
    return color;
#else
    return 0;
#endif
}

half3 CrystalBRDFSpecular(half3 crystalColor, half crystalRange, half3 detailNormalWS, 
          Light light, half viewDirectionWS, half NdotL)
{
    BRDFData brdfData = (BRDFData)0;
    brdfData.specular = crystalColor;
    brdfData.perceptualRoughness = crystalRange;
    brdfData.roughness = max( PerceptualRoughnessToRoughness(  brdfData.perceptualRoughness), 0.0078125f);
    brdfData.roughness2 = max(  brdfData.roughness * brdfData.roughness, 6.103515625e-5);
    brdfData.normalizationTerm = brdfData.roughness * 4.0h + 2.0h;
    brdfData.roughness2MinusOne = brdfData.roughness2 - 1.0h;
    
    return DirectBRDFSpecular(brdfData, detailNormalWS, light.direction, viewDirectionWS) * NdotL * lerp(_ShadowColor, light.color, light.shadowAttenuation) * light.distanceAttenuation;
}

// isSkin

half3 LightingPhysicallyBasedSkin(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half distanceAttenuation, half shadowAttenuation, half3 normalWS, half3 viewDirectionWS,
half NdotL, half NdotLUnclamped, half DNdotL, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT), half curvature, half isSkin )
{
    half3 diffuseLighting = brdfData.diffuse * SAMPLE_TEXTURE2D_LOD(_SkinLUT, sampler_SkinLUT, float2(NdotLUnclamped * 0.5 + 0.5), 0 ).rgb;
    half NLOffset = DNdotL - NdotL;
    half lightAttenuation = distanceAttenuation * shadowAttenuation;
    half lutUV2 = lightAttenuation * (1 + NLOffset);
    float3 sssShadowPower = float3(lerp(lutUV2 ,sqrt(lutUV2), curvature ), lutUV2, lutUV2);
    diffuseLighting = diffuseLighting * sssShadowPower;
    diffuseLighting = lerp(brdfData.diffuse * NdotL, diffuseLighting, isSkin);

    #if defined(_ROLE_HIGH_BRDF) && !defined(_ROLE_SIMPLE_ON)
        return (DirectBRDFHighSepcular( brdfData, normalWS, lightDirectionWS, viewDirectionWS ) * NdotL + diffuseLighting) * lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation;
    #else
        return (DirectBRDFSepcular( brdfData, normalWS, lightDirectionWS, viewDirectionWS ) * NdotL + diffuseLighting) * lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation;
    #endif

}

half3 LightingPhysicallyBasedSkin(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS,
half NdotL, half NdotLUnclamped, half DNdotL, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT),half curvature,half isSkin)
{
    return LightingPhysicallyBasedSkin(brdfData, light.color, light.direction, light.distanceAttenuation,normalWS, viewDirectionWS,
    NdotL,NdotLUnclamped,DNdotL,TEXTURE2D_ARGS(_SkinLUT, sampler_SkinLUT), curvature, isSkin);
}

half4 UniversalSkinFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion,
half3 emission, half alpha, half fresnelScale, half isSkin, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT), half curvature,
half4 translucency, half3 subsurfaceColor, half3 detailNormalWS, half3 bentNormal, half backscatter, half3 crystalColor, half crystalRange )
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight(inputData.shadowCoord);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif
    
    mainLight.color *= _RoleMainLightIntensity;
    mainLight.shadowAttenuation = lerpWhiteTo(mainLight.shadowAttenuation , _RoleShadowIntensity );

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));

    half ambientIntensity = lerp(_RoleShadowIntensity);
    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, ambientIntensity, _RoleReflectionIntensity);

    // back scattering
    color += backscatter * SampleSH(-inputData.normalWS) * albedo * occlusion * translucency.x * subsurfaceColor * isSkin;

    half NdotLUnclamped = dot(inputData.normalWS, mainLight.direction);
    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half DNdotL = saturate(dot(detailNormalWS, mainLight.direction));
    color += LightingPhysicallyBaseSkin(brdfData, mainLight,detailNormalWS, inputData.viewDirectionWS, NdotL,NdotLUnclamped, DNdotL, TEXTURE2D_ARGS(_SkinLUT,sampler_SkinLUT), curvature, isSkin );

    //Subsurface scattering
    half transShadowAtten = min(mainLight.shadowAttenuation, occlusion);
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot(transLightDir, -inputData.viewDirectionWS);
    transDot = exp2( saturate(transDot) * transPower - transPower );
    color += isSkin * subsurfaceColor * transDot * ( 1.0 - NdotLUnclamped ) * mainLight.color * lerp(1.0h, transShadowAtten, translucency.z) * translucency.x;

    //Crystal 
    #if defined(_CRYSTAL_ON) && !defined(_ROLE_SIMPLE_ON) && defined(_ROLE_CRSTALON)
        color += CrystalBRDFSpecular(crystalColor, crystalRange, detailNormalWS, mainLight, inputData.viewDirectionWS,NdotL) * isSkin;
    #endif

    //
    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; i++ )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS);

            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color  *= aoFactor.directAmbientOcclusion; 
            #endif

            NdotLUnclamped = dot(inputData.normalWS, light.direction);
            NdotL = saturate( dot(inputData.normalWS, light.direction));
            DNdotL = saturate(dot(detailNormalWS, mainLight.direction));
            color += LightingphysicallyBaseSkin(brdfData, light, detailNormalWS, inputData.viewDirectionWS, NdotL, NdotLUnclamped, DNdotL, TEXTURE2D_ARGS(_SkinLUT, sampler_SkinLUT),curvature, isSkin);

            //Crystal
            #if defined(_CRYSTAL_ON) && !defined(_ROLE_SIMPLE_ON) && defined(_ROLE_CRSTALON)
                color += CrystalBRDFSpecular(crystalColor, crystalRange, detailNormalWS, light, inputData.viewDirectionWS, NdotL) * isSkin;
            #endif

        }

    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLight * brdfData.diffuse;
    #endif
    color += emission;
    return half4(color, alpha);
}

// Skin
half3 LightingPhysicallyBasedSkin(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half distanceAttenuation, half shadowAttenuation, half3 normalWS, half3 viewDirectionWS,
half NdotL, half NdotLUnclamped, half DNdotL, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT), half curvature )
{
    half3 diffuseLighting = brdfData.diffuse * SAMPLE_TEXTURE2D_LOD(_SkinLUT, sampler_SkinLUT, float2(NdotLUnclamped * 0.5 + 0.5), 0 ).rgb;
    half NLOffset = DNdotL - NdotL;
    half lightAttenuation = distanceAttenuation * shadowAttenuation;
    half lutUV2 = lightAttenuation * (1 + NLOffset);
    float3 sssShadowPower = float3(lerp(lutUV2 ,sqrt(lutUV2), curvature ), lutUV2, lutUV2);
    diffuseLighting = diffuseLighting * sssShadowPower;    

    #if defined(_ROLE_HIGH_BRDF) && !defined(_ROLE_SIMPLE_ON)
        return (DirectBRDFHighSepcular( brdfData, normalWS, lightDirectionWS, viewDirectionWS ) * NdotL + diffuseLighting) * lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation;
    #else
        return (DirectBRDFSepcular( brdfData, normalWS, lightDirectionWS, viewDirectionWS ) * NdotL + diffuseLighting) * lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation;
    #endif
}


half3 LightingPhysicallyBasedSkin(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS,
half NdotL, half NdotLUnclamped, half DNdotL, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT),half curvature)
{
    return LightingPhysicallyBasedSkin(brdfData, light.color, light.direction, light.distanceAttenuation,normalWS, viewDirectionWS,
    NdotL,NdotLUnclamped,DNdotL,TEXTURE2D_ARGS(_SkinLUT, sampler_SkinLUT), curvature);
}


half4 UniversalSkinFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion,
half3 emission, half alpha, half fresnelScale, TEXTURE2D_PARAM(_SkinLUT, sampler_SkinLUT), half curvature,
half4 translucency, half3 subsurfaceColor, half3 detailNormalWS, half3 bentNormal, half backscatter, half3 crystalColor, half crystalRange )
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight(inputData.shadowCoord);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
#endif
    
    mainLight.color *= _RoleMainLightIntensity;
    mainLight.shadowAttenuation = lerpWhiteTo(mainLight.shadowAttenuation , _RoleShadowIntensity );

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));
    half ambientIntensity = lerp(_RoleShadowIntensity);

    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, ambientIntensity, _RoleReflectionIntensity);

    // back scattering
    color += backscatter * SampleSH(-inputData.normalWS) * albedo * occlusion * translucency.x;

    half NdotLUnclamped = dot(inputData.normalWS, mainLight.direction);
    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));
    half DNdotL = saturate(dot(detailNormalWS, mainLight.direction));
    color += LightingPhysicallyBaseSkin(brdfData, mainLight,detailNormalWS, inputData.viewDirectionWS, NdotL,NdotLUnclamped, DNdotL, TEXTURE2D_ARGS(_SkinLUT,sampler_SkinLUT), curvature);

    //Subsurface scattering
    half transShadowAtten = min(mainLight.shadowAttenuation, occlusion);
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot(transLightDir, -inputData.viewDirectionWS);
    transDot = exp2( saturate(transDot) * transPower - transPower );
    color += subsurfaceColor * transDot * ( 1.0 - NdotLUnclamped ) * mainLight.color * lerp(1.0h, transShadowAtten, translucency.z) * translucency.x;

    //Crystal 
    #if defined(_CRYSTAL_ON) && !defined(_ROLE_SIMPLE_ON)
        color += CrystalBRDFSpecular(crystalColor, crystalRange, detailNormalWS, mainLight, inputData.viewDirectionWS,NdotL);
    #endif

    //
    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
        for(int i = 0; i < pixelLightCount; i++ )
        {
            Light light = GetAdditionalLight(i, inputData.positionWS);

            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color  *= aoFactor.directAmbientOcclusion; 
            #endif

            NdotLUnclamped = dot(inputData.normalWS, light.direction);
            NdotL = saturate( dot(inputData.normalWS, light.direction));
            DNdotL = saturate(dot(detailNormalWS, mainLight.direction));
            color += LightingphysicallyBaseSkin(brdfData, light, detailNormalWS, inputData.viewDirectionWS, NdotL, NdotLUnclamped, DNdotL, TEXTURE2D_ARGS(_SkinLUT, sampler_SkinLUT),curvature);

            //Crystal
            #if defined(_CRYSTAL_ON) && !defined(_ROLE_SIMPLE_ON) && defined(_ROLE_CRSTALON)
                color += CrystalBRDFSpecular(crystalColor, crystalRange, detailNormalWS, light, inputData.viewDirectionWS, NdotL);
            #endif
        }

    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLight * brdfData.diffuse;
    #endif
    color += emission;
    return half4(color, alpha);
}

half4 UniversalSimpleRoleFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half fresnelScale)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight( inputData.shadowCoord );
    mainLight.color *= _RoleMainLightIntensity;
    mainLight.shadowAttenuation = LerpWhiteTo(mainLight.shadowAttenuation, _RoleShadowIntensity);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half ambientIntensity = _RoleAmbientIntensity;
    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,
    fresnelScale, ambientIntensity, _RoleReflectionIntensity);

    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction));

    color += LightingPhysicallyBasedWrapped(brdfData, mianLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

#if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();
    for(uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        NdotL = saturate(dot(inputData.normalWS, light.direction));
        color += LightingPhysicallyBaseWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
    }
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX)
    color += inputData.vertexLight * brdfData.diffuse;
#endif

#if defined(_EMISSION)
     color += emission;
#endif
    return half4(color, alpha);
}


// Cloth
half3 LightingPhysicallyBasedCloth(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half distanceAttenuation,half shadowAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 diffuseLighting = brdfData.diffuse * NdotL;

    half3 shadowColor = lerp(_ShadowColor, lightColor, shadowAttenuation) * distanceAttenuation;

#if defined(_ROLE_HIGH_BRDF) && !defined(_ROLE_SIMPLE_ON)    
    half3 specularColor = DirectBRDFHighSepcular(brdfData, normalWS, lightDirectionWS) * NdotL;    
#else
    half3 specularColor = DirectBRDFSepcular(brdfData, normalWS, lightDirectionWS) * NdotL;
#endif

    return (specularColor + diffuseLighting) * shadowColor;
}

half3 LightingPhysicallyBasedCloth(BRDFData inputData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingPhysicallyBasedCloth(brdfData, light.color, light.direction, light.distanceAttenuation, light.shadowAttenuation, normalWS, viewDirectionWS);
}

half4 UniversalClothFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half fresnelScale)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);
    Light mainLight = GetMainLight(inputData.ShadowCoord);

#if defined(_SCREEN_SPACE_OCCLUSION)
    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
    mainLight.color *= aoFactor.directAmbientOcclusion;
    occlusion = min( occlusion, aoFactor.indirectAmbientOcclusion);
#endif

    mainLight.color *= _RoleMainLightIntensity;
    mainLight.shadowAttenuation = LerpWhiteTo(mainLight.shadowAttenuation, _RoleShadowIntensity);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));

    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, _RoleAmbientIntensity, _RoleReflectionIntensity);

    color += LightingPhysicallyBasedCloth(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

    #if defined(_ADDITIONAL_LIGHTS)
        int pixelLightCount = GetAdditionalLightsCount();
       for(uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            color += LightingPhysicallyBasedCloth(brdfData, light, inputData.normalWS, inputData.viewDirectionWS );            
        }
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLight * brdfData.diffuse;
    #endif

    color += emission;

    return half4(color, alpha);
}

//--- hair

inline half3 AnisoD(half3 normalWS, half3 strandDirWS, half3 H, half roughness, half shift)
{
    half3 shiftTangent = ShiftTangent(strandDirWS, normalWS, shift);
    return D_KajiyaKay(shiftTangent, H, roughness);
}

inline half3 DirectBRDFHair(half3 albedo, half3 specular, half3 normalWS, half geomNdotV, half3 lightDirectionWS, half3 viewDirectionWS, half3 strandDirWS,
    half roughness1, half shift1, half3 specColor1, half roughness2, half shift2, half3 specColor2)
{
    half NdotL = dot(normalWS, lightDirectionWS);
    half LdotV = dot(lightDirectionWS, viewDirectionWS);
    half invLenLV = rsqrt(max(2.0 * LdotV + 2.0, REAL_EPS));
    half3 H = (lightDirectionWS + viewDirectionWS) * invLenLV;

    half3 halfDir = SafeNormalize_Half3(lightDirectionWS + viewDirectionWS);
    half NdotH = saturate(dot(normalWS, halfDir));
    half LdotH = saturate(dot(lightDirectionWS, halfDir));

    half3 F = F_Schlick(specular, LdotH);

    half3 t1 = ShiftTangent(strandDirWS, normalWS, shift1);
    half3 anisoD1 = D_KajiyaKay(t1, H, roughness1) * specColor1;
    half3 t2 = ShiftTangent(strandDirWS, normalWS, shift2);
    half3 anisoD2 = D_KajiyaKay(t2, H, roughness2) * specColor2;
    half3 anisoD = anisoD1 + anisoD2;

    half3 specularTerm = 0.25h * F * anisoD * saturate(NdotL) * saturate(geomNdotV, REAL_MAX);

    half3 diffuse = albedo * saturate(NdotL);
    half3 color = specularTerm + diffuse;
    return color;
}

inline half3 LightingPhysicallyBasedHair(half3 albedo, half3 specular, Light light, half3 normalWS, half geomNdotV, half3 viewDirectionWS, half3 strandDirWS,
half roughness1, half shift1, half3 specColor1,half roughness2, half shift2, half3 specColor2)
{
    half3 blendColor = lerp(_ShadowColor, light.color, light.shadowAttenuation) * light.distanceAttenuation;
    return blendColor * DirectBRDFHair(albedo, specular, normalWS, geomNdotV, light.direction, viewDirectionWS, strandDirWS,
    roughness1, shift1, specColor1, roughness2, shift2, specColor2);
}

inline half3 EnvironmentBRDFHair(half3 albedo, half3 specular, half roughness, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * albedo;
    half surfaceReducation = 1.0 / ( roughness * roughness +1.0 );
    half reflectivity = ReflectivitySpecular(specular);
    half grazingTerm = saturate((1.0h - roughness) + reflectivity);
    c += surfaceReducation * indirectSpecular * lerp(specular, grazingTerm, fresnelTerm);
    return c;
}

half3 GlobalIlluminationHair(half3 albedo, half3 specular, half roughness, half perceptualRoughness, half occlusion, half3 bakedGI,
    half3 normalWS, half3 viewDirectionWS, half NdotV, half ambientReflection )
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - NdotV);

    half3 indirectDiffuse = bakedGI * occlusion * _RoleAmbientIntensity;
    half3 indirectSpecular = RoleGlossyEnvironmentReflection(reflectVector, perceptualRoughness, occlusion) * ambientReflection * _RoleReflectionIntensity;

    return EnvironmentBRDFHair(albedo, specular, roughness, indirectDiffuse, indirectSpecular, fresnelTerm);
}
//---hair end


//---Eye

half3 LightingPhysicallyBasedEye(BRDFData brdf,Light light, half normalWS, half3 viewDirectionWS, half highlightPower, half highlightAtten)
{
    half NdotL = saturate( dot(normalWS, viewDirectionWS) );
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    half3 diffuseLight = brdf.diffuse * light.color * lightAttenuation * NdotL;

    half3 H = SafeNormalize_Half3(viewDirectionWS + light.direction);
    half3 specularLight = pow(max(0.0001, dot(normalWS, H)), highlightPower) * lightAttenuation * light.color * highlightAtten;
    return diffuseLight + specularLight;
}

half4 UniversalEyeFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha,
    half fresnelScale, half highlightPower, half highlightAtten)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, _RoleAmbientIntensity, _RoleReflectionIntensity);
    color += LightingPhysicallyBasedEye(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, highlightPower, highlightAtten);

    #if defined(_ADDITIONAL_LIGHTS)
        uint pixelLightCount = GetAdditionalLightsCount();
        for(uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            color += LightingPhysicallyBasedEye(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, highlightPower, highlightAtten * _RoleEyeAdditiveSpecIntensity);
        }
    #endif
    
    #if _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += emission;

    return half4(color, alpha);
}
//Eye Cornea
half3 LightingPhysicallyBasedCornea(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half specularMask)
{
    half NdotL = saturate( dot(normalWS, light.direction) );
    half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
    half3 radiance = light.color * lightAttenuation * NdotL;
    return DirectBRDF(brdfData, normalWS, light.direction, viewDirectionWS) * radiance * specularMask;
}

half4 UniversalCorneaFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half fresnelScale, half IBLMask, half specularMask)
{
    BRDFData  brdfData;
    InitializeBRDFData (albedo, metallic, specular, smoothness, alpha, brdfData);
    Light mainLight = GetMainLight(inputData.shadowCoord);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));

    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, _RoleAmbientIntensity, _RoleReflectionIntensity * IBLMask);
    color += LightingPhysicallyBasedCornea(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, specularMask);

    #if defined(_ADDITIONAL_LIGHTS)
        uint pixelLightCount = GetAdditionalLightsCount();
        for(uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            color += LightingPhysicallyBasedCornea(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, specularMask;
        }
    #endif
    
    #if _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += emission;

    return half4(color, alpha);
}
//---Eye End


//---Fur---

half4 UniversalFurFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular, half smoothness, half occlusion, half3 emission, half alpha, half fresnelScale)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight(inputData.shadowCoord);
    mainLight.shadowAttenuation = ApplyMicroShadow(occlusion, inputData.normalWS, mainLight.direction, mainLight.shadowAttenuation);

    MixRealTimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0,0,0,0));

    half3 color = GlobalIlluminationRole(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, fresnelScale, _RoleAmbientIntensity, _RoleReflectionIntensity);
    color += LightingPhysicallybased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for(uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
            color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += emission;
    return half4(color, alpha);
}

#endif