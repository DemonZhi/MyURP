#ifndef TOD_SCATTERING_INCLUDED
#define TOD_SCATTERING_INCLUDED

#ifndef TOD_SCATTERING_SAMPLES
#define TOD_SCATTERING_SAMPLES 2
#endif

#ifndef TOD_SCATTERING_MIE
#define TOD_SCATTERING_MIE 1
#endif

#ifndef TOD_SCATTERING_RAYLEIGH
#define TOD_SCATTERING_RAYLEIGH 1
#endif

#ifndef TOD_BAYER_DIM
#define TOD_BAYER_DIM 8
#endif

#include "../Base/Includes/MyEngine_Fog.hlsl"
#include "../Base/Includes/MyEngine_Common.hlsl"


uniform sampler2D _CloudDensityMap;
uniform float4 _CloudDensityMap_ST;
half _CloudShadowScale;
half _CloudShadowCutoff;
half _CloudShadowFadeEnd;

inline float Scale(float inCos)
{
    float x = 1 - inCos;
    return 0.25 * exp(-0.00287 + (x * (0.459 + x * (-6.8 + x * 5.25))));
}

inline float MiePhase(float eyeCos, float eyeCos2)
{
    return TOD_kBetaMie.x * (1.0 + eyeCos2) / pow(abs(TOD_kBetaMie.y + TOD_kBetaMie.z * eyeCos), 1.5);
}

inline float RayleighPhase(float eyeCos2)
{
    return 0.75 + 0.75 * eyeCos2;
}

inline float3 CloudPhase(float eyeCos, float eyeCos2)
{
    const float g = 0.3;
    const float g2 = g*g;
    return TOD_CloudScattering * (1.5 * (1 - g2) / (2 + g2) * (1 + eyeCos2) / (1 + g2 - 2 * g * eyeCos) + g * eyeCos );
}

inline float3 NightPhase(float3 dir)
{
    dir.y = max(0, dir.y);    
    return TOD_MoonSkyColor * (1.0 - 0.75 * dir.y);
}

inline float3 MoonPhase(float3 dir)
{
    return TOD_MoonHaloColor * pow(max(0, dot(dir, TOD_LocalMoonDirection)), TOD_MoonHaloPower);
}

inline float3 PostProcess(float3 col,float3 dir)
{
    col = lerp(col, TOD_GroundColor, saturate(-dir.y));

    //col = lerp(col, TOD_FogColor, TOD_Fogginess);

    col = pow( abs(col * TOD_Brightness), TOD_Contrast);

    return col;
}

#if TOD_SCATTERING_RAYLEIGH && TOD_SCATTERING_MIE
inline void ScatteringCoefficients(float3 dir, out float3 inscatter, out float3 outscatter)
#elif TOD_SCATTERING_RAYLEIGH
inline void ScatteringCoefficients(float3 dir, out float3 inscatter)
#else
inline void ScatteringCoefficients(float3 dir, out float3 outscatter)
#endif
{
    dir = SafeNormalize_Half3(float3(dir.x , max(0, dir.y), dir.z));

    float kInnerRadius = TOD_kRadius.x;
    float kInnerRadius2 = TOD_kRadius.y;
    float kOuterRadius2 = TOD_kRadius.w;

    float kScale = TOD_kScale.x;
    float kScaleOverScaleDepth = TOD_kScale.z;
    float kCameraHeight = TOD_kScale.w;

    float3 kKr4PI = TOD_k4PI.xyz;
    float3 kKm4PI = TOD_k4PI.w;

    float3 kKrESun = TOD_kSun.xyz;
    float3 kKmESun = TOD_kSun.w;

    float3 cameraPos = float3(0, kInnerRadius + kCameraHeight, 0);

    float far = sqrt(kOuterRadius2 + kInnerRadius2 * dir.y * dir.y - kInnerRadius2) - kInnerRadius * dir.y;

    float startDepth = exp(kScaleOverScaleDepth * (-kCameraHeight));
    float startAngle = dot(dir, cameraPos) / (kInnerRadius + kCameraHeight);
    float startOffset = startDepth * Scale(startAngle);

    //Scattering loop
    float sampleLength = far / float(TOD_SCATTERING_SAMPLES);
    float scaledLength = sampleLength * kScale;
    float3 sampleRay = dir * sampleLength;
    float3 samplePoint = cameraPos + sampleRay * 0.5;

    float3 sunColor = float3 (0,0,0);

    for(int i = 0; i < int(TOD_SCATTERING_SAMPLES); i++)
    {
        float height = max(1, length(samplePoint));
        float invHeight = 1.0 / height;

        float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
        float atten = depth * scaledLength;

        float cameraAngle = dot(dir, samplePoint)* invHeight;
        float sunAngle = dot(TOD_LocalSunDirection, samplePoint) * invHeight;
        float sunScatter = startOffset + depth * (Scale(sunAngle) - Scale(cameraAngle));

        float3 sunAtten = exp(-sunScatter * (kKr4PI + kKm4PI));

        sunColor += sunAtten * atten;
        samplePoint += sampleRay;
    }
    
    #if TOD_SCATTERING_RAYLEIGH
        inscatter = TOD_SunSkyColor * sunColor * kKrESun;
    #endif

    #if  TOD_SCATTERING_MIE
        outscatter = TOD_SunSkyColor * sunColor * kKmESun;
    #endif    
}

#if TOD_SCATTERING_RAYLEIGH && TOD_SCATTERING_MIE
inline float4 ScatteringColor(float3 dir, float3 inscatter, float3 outscatter)
#elif TOD_SCATTERING_RAYLEIGH
inline float4 ScatteringColor(float3 dir, float3 inscatter)
#else
inline float4 ScatteringColor(float3 dir, float3 outscatter)
#endif
{
    float3 resultColor = float3(0, 0, 0);

    float sunCos = dot(TOD_LocalSunDirection, dir);
    float sunCos2 = sunCos * sunCos;

    #if TOD_SCATTERING_RAYLEIGH
        resultColor += NightPhase(dir);
    #endif

    #if TOD_SCATTERING_MIE
        resultColor += MoonPhase(dir);
    #endif

    #if TOD_SCATTERING_RAYLEIGH
        resultColor += RayleighPhase(sunCos2) * inscatter;
    #endif

    #if TOD_SCATTERING_MIE
        resultColor += MiePhase(sunCos, sunCos2) * outscatter;
    #endif

    return float4(PostProcess(resultColor, dir), 1.0);
}

inline float4 ScatteringColor(float3 dir)
{
    #if TOD_SCATTERING_RAYLEIGH && TOD_SCATTERING_MIE
        float3 inscatter, outscatter;
        ScatteringCoefficients(dir, inscatter, outscatter);
        return ScatteringColor(dir, inscatter, outscatter);
    #elif TOD_SCATTERING_RAYLEIGH
        float3 inscatter;
        ScatteringCoefficients(dir, inscatter);
        return ScatteringColor(dir, inscatter);
    #else
        float3 outscatter;
        ScatteringCoefficients(dir, outscatter);
        return ScatteringColor(dir, outscatter);
    #endif
}

inline float FogDensityMaximum(float3 worldPos)
{
    float3 objectPos = worldPos;
    float3 cameraPos = _WorldSpaceCameraPos;

    float startDistance = TOD_ScatterDensity.w;
    float cameraDistance = length(objectPos - cameraPos);

    float globalDensity = TOD_ScatterDensity.z;
    float heightDensity = max(0.01, TOD_ScatterDensity.x * (min(objectPos.y, cameraPos.y) - TOD_ScatterDensity.y));
    float heightDensityExpInv = exp(-heightDensity);

    float fogIntensity = max(0, cameraDistance - startDistance);

    fogIntensity *= heightDensityExpInv * (1.0 - heightDensityExpInv) / heightDensity;

    fogIntensity = min(10, globalDensity * fogIntensity);

    return 1 - exp(- fogIntensity);
}

inline float FogDensityAverage(float3 worldPos)
{
    float3 objectPos = worldPos;
    float3 cameraPos =  _WorldSpaceCameraPos;

    float startDistance = TOD_ScatterDensity.w;
    float cameraDistance = length(objectPos - cameraPos);

    float globalDensity = TOD_ScatterDensity.z;
    float heightDensityObject = max(0.01, TOD_ScatterDensity.x * (objectPos.y - TOD_ScatterDensity.y));
    float heightDensityCamera = max(0.01, TOD_ScatterDensity.x * (cameraPos.y - TOD_ScatterDensity.y));
    float heightDensityObjectExpInv = exp(-heightDensityObject);
    float heightDensityCameraExpInv = exp(-heightDensityCamera);

    float fogIntensity = max(0, cameraDistance - startDistance);

    float fogIntensityObject = heightDensityObjectExpInv * (1 - heightDensityObjectExpInv) / heightDensityObject;
    float fogIntensityCamera = heightDensityCameraExpInv * (1 - heightDensityCameraExpInv) / heightDensityCamera;

    fogIntensity *= (fogIntensityObject + fogIntensityCamera) * 0.5;
    return 1 - exp(- fogIntensity);
}


inline float FogDensity(float3 worldPos)
{
    return FogDensityAverage(worldPos);
}

inline float4 AtmosphericScattering(float3 cameraRay, float3 worldPos, float depth, float mask)
{
    float3 dir = SafeNormalize_Half3( mul((float3x3)TOD_World2Sky, cameraRay));
    #if TOD_SCATTERING_RAYLEIGH && TOD_SCATTERING_MIE
        float3 inscatter, outscatter;
        ScatteringCoefficients(dir, inscatter, outscatter);       
    #elif TOD_SCATTERING_RAYLEIGH
        float3 inscatter;
        ScatteringCoefficients(dir, inscatter);       
    #else
        float3 outscatter;
        ScatteringCoefficients(dir, outscatter);        
    #endif

    if(depth != 1)
    {
        depth = FogDensity(worldPos);
        #if TOD_SCATTERING_MIE
            outscatter = outscatter * depth * mask;
        #endif

        #if TOD_SCATTERING_RAYLEIGH
            inscatter = inscatter * depth;
        #endif
    }

    #if TOD_SCATTERING_RAYLEIGH && TOD_SCATTERING_MIE
        float3  color = ScatteringColor(dir, inscatter, outscatter).rgb;
    #elif TOD_SCATTERING_RAYLEIGH
        float3  color = ScatteringColor(dir, inscatter).rgb;
    #else
        float3  color = ScatteringColor(dir, outscatter).rgb;
    #endif

    return float4(color, depth);
}

inline float4 AtmosphericScattering(float3 cameraRay, float3 worldPos, float depth  )
{
    const float mask = 1;
    return AtmosphericScattering(cameraRay, worldPos, depth, mask);
}

inline float2 DitheringCoords(float2 screenPos)
{
    return screenPos * _ScreenParams.xy * (1.0 / TOD_BAYER_DIM);
}

inline float2 DitheringColor(float2 uv)
{
    return tex2D(TOD_BayerTexture, uv).a * (1.0 / (TOD_BAYER_DIM * TOD_BAYER_DIM + 1.0));
}

#endif