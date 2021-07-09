#ifndef MYENGINE_WIND_INCLUDED
#define MYENGINE_WIND_INCLUDED

#include "./MyEngine_Common.hlsl"

// Wind
TEXTURE2D(_WindTexture); SAMPLER(sampler_WindTexture);

half4 _WindDirectionSize;
half4 _WindStrengthMultipliers;
half4 _WindSinTime;

TEXTURE2D(_GrassDisplacementRT); SAMPLER(sampler_GrassDisplacementRT);

float4 _GrassDisplacementPosition;

void AnimateFoliageVertex(half4 animParams, half sampleSize, half4 windMultiplier, half3 normalOS, inout float3 positionOS)
{
#if defined(_FOLIAGE_ANIMATE)
    float origLength = length(positionOS.xyz);
    half3 windDir = mul(UNITY_MATRIX_I_M, float4(_WindDirectionSize.xyz, 0)).xyz;

    half fDetailAmp = 0.1h;

    float2 samplePos = TransformObjectToWorld(positionOS.xyz * sampleSize).xz * _WindDirectionSize.ww;

    half4 wind = SAMPLE_TEXTURE2D_LOD(_WindTexture, sampler_WindTexture, samplePos.xy, windMultiplier.w);

    animParams.abg *= windMultiplier.xyz;
    animParams.ab *= 2;

    // Primary bending
    positionOS.xz += animParams.a * windDir.xz * _WindStrengthMultipliers.y * smoothstep(-1.5h, 1.0h, wind.r * (wind.g * 1.0h - 0.243h));

    //Second Texture sample taking phase into account
    wind = SAMPLE_TEXTURE2D_LOD(_WindTexture, sampler_WindTexture, samplePos.xy - animParams.rr * 0.5, windMultiplier.w);

    // edge flutter
    half3 bend = normalOS.xyz * (animParams.g * fDetailAmp * lerp(_WindSinTime.y, _WindSinTime.z, wind.r));
    bend.y = animParams.b * 0.3h;

    // edge flutter and secondary Bending
    positionOS.xyz += (bend + (animParams.b * windDir * wind.r * (wind.g * 2.0h - 0.243h ))) * _WindStrengthMultipliers.y;

    positionOS.xyz = SafeNormalize_Half3(positionOS.xyz) * origLength;

#endif
}

    void AnimateFlagVertex(half lengthOffset, half waveSpeed, half frequencyScale, half3 waveDirection, half noiseVal, half waveAttenuation, half2 uv, half objectSpaceScale, half3 windScale, inout float3 positionOS)
    {
        //wind direction in objSpace
        half3 windDir = mul(UNITY_MATRIX_I_M, float4(_WindDirectionSize.xyz, 0)).xyz;
        float2 samplePos = TransformObjectToWorld(positionOS.xyz * objectSpaceScale).xz * _WindDirectionSize.ww;
        // wind Texture
        half4 windTextureColor = SAMPLE_TEXTURE2D_LOD(_WindTexture, sampler_WindTexture, samplePos.xy, 0);
        windDir.xz *= _WindStrengthMultipliers.w * smoothstep(-1.5h, 1.0h, windTextureColor.r * (windTextureColor.g * 1.0h - 0.243h));

        // sin
        half sinx = frequencyScale *( (uv.y * 6.26) + (_Time.y * waveSpeed * _WindStrengthMultipliers.w) );
        half sinValue = waveAttenuation * sin(sinx);

        // wave offset
        half3 waveOffset = noiseVal * sinValue * waveDirection + (windDir * waveAttenuation * windScale);

        waveOffset.y += lengthOffset * waveAttenuation;

        positionOS.xyz += waveOffset;
    }

#endif