#ifndef MYENGINE_URP_SSR_INCLUDED
#define MYENGINE_URP_SSR_INCLUDED

#if defined(_SSR_ORTHO_ON)
    inline float GetOrthoEyeDepth(float rawDepth)
    {
        #if defined(_UNITY_REVERSED_Z)
            #if UNITY_REVERSED_Z == 1
                rawDepth = 1.0f - rawDepth;
            #endif
        #endif
        return lerp(_ProjectionParams.y, _ProjectionParams.z, rawDepth);
    }
#endif

float UVJitter(in float2 uv)
{
    float dotUV = frac( dot(uv, float2(0.06711056, 0.00583715)));

    return frac( 52.9829189 * dotUV  );
}

void SSRRayConvert(float3 worldPos, out float4 clipPos, out float3 screenPos)
{
    clipPos = TransformWorldToHClip(worldPos);
    float k = rcp(clipPos.w);

    screenPos.xy = ComputeScreenPos(clipPos).xy * k;

    #if defined(_SSR_ORTHO_ON)
        screenPos.z = GetOrthoEyeDepth(clipPos.z);
        clipPos.w = screenPos.z;
    #else
        screenPos.z = k;
    #endif

    #if defined(UNITY_SINGLE_PASS_STEREO)
        screenPos.xy = UnityStereoTransformScreenSpaceTex(screenPos.xy);
    #endif    

}

float3 SSRRayMarch(float4 positionCS, float3 positionWS, float3 reflectDir, half maxSampleCount, float sampleStep, half jitter)
{
    float4 startClipPos;
    float3 startScreenPos;
    SSRRayConvert(positionWS + reflectDir, startClipPos, startScreenPos);

    float4 endClipPos;
    float3 endScreenPos;
    SSRRayConvert(positionWS + reflectDir, endClipPos, endScreenPos);
    
    if( endClipPos.w < endClipPos.w )
    {
        return float3(0, 0, 0);
    }

    float3 screenDir = endScreenPos - startScreenPos;

    float screenDirX = abs(screenDir.x);
    float screenDirY = abs(screenDir.y);

    float dirMultiplier = lerp( 1/ (_ScreenParams.y * screenDirY ), 1 / (_ScreenParams.x * screenDirX), screenDirX > screenDirY ) * sampleStep;

    screenDir *= dirMultiplier;

    half lastRayDepth = startClipPos.w;

    half sampleCount = 1 + UVJitter(positionCS.xy) * jitter;

    float3 lastScreenMarchUVZ = startScreenPos;
    float lastDeltaDepth = 0;

#if defined(SHADER_API_OPENGL) || defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12)
    [unroll(32)]
#else
    UNITY_LOOP
#endif

    for(int i = 0; i < maxSampleCount; i++)
    {
        float3 screenMarchUVZ = startScreenPos + screenDir * sampleCount;

        #if defined(_SSR_ORTHO_ON) 
            half rayDepth = screenMarchUVZ.z;
        #else
            half rayDepth = rcp(screenMarchUVZ.z);
        #endif

        if(rayDepth >= _ProjectionParams.z + 1.0 || screenMarchUVZ.x <= 0 || screenMarchUVZ.x >= 1 || screenMarchUVZ.y <= 0 || screenMarchUVZ.y >= 1) 
        {
            break;
        }

        #if defined(_SSR_ORTHO_ON)
            float sceneDepth = GetOrthoEyeDepth( SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenMarchUVZ.xy));
        #else
            float sceneDepth = LinearEyeDepth( SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenMarchUVZ.xy), _ZBufferParams);
        #endif
        half deltaDepth = rayDepth - sceneDepth;

        if(  (deltaDepth > 0) && (sceneDepth > startClipPos.w) && (deltaDepth < abs(rayDepth - lastRayDepth) * 2) )
        {
            float samplePercent = saturate(lastDeltaDepth / (lastDeltaDepth - deltaDepth ));
            samplePercent = lerp(samplePercent, 1, rayDepth >= _ProjectionParams.z);
            float3 hitScreenUVZ = lerp(lastScreenMarchUVZ, screenMarchUVZ, samplePercent);
            return float3(hitScreenUVZ.xy, 1);
        }

        lastRayDepth = rayDepth;
        sampleCount  += 1;

        lastScreenMarchUVZ = screenMarchUVZ;
        lastDeltaDepth = deltaDepth;
    }   

    float4 farClipPos;
    float3 farScreenPos;

    SSRRayConvert( positionWS + reflectDir * 10000, farClipPos, farScreenPos );

    if( (farScreenPos.x >0) && (farScreenPos.x < 1 ) && farScreenPos.y > 0  && farScreenPos.y < 1 )
    {
        #if defined(_BGWATER_ORTHO_ON)
            float farDepth = GetOrthoEyeDepth ( SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, farScreenPos.xy)); 
        #else
            float farDepth = LinearEyeDepth ( SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, farScreenPos.xy), _ZbufferParams); 
        #endif

        if(farDepth > startClipPos.w)
        {
            float alphaFadeout = smoothstep(1, 0.85, farScreenPos.y);
            return float3(farScreenPos.xy, alphaFadeout);
        }
    }
    return float3(0,0,0);
}

float3 GetSSRUVZ(float4 positionCS, half NoV, float2 screenUV, float3 positionWS, float3 reflectDir, half maxSampleCount, float sampleStep, half jitter)
{
    float3 result = float3(0,0,0);

    #if defined(UNITY_SINGLE_PASS_STERO)
        half ssrWeight = 1;
        NoV = NoV *2;
        ssrWeight *=  1 - (NoV * NoV); 
    #else
        float widthEdge = screenUV.x *2 -1;
        widthEdge *= widthEdge;
        half ssrWeight = saturate(1  - widthEdge * widthEdge);
    #endif

    if(ssrWeight > 0.005)
    {
        float3 uvz = SSRRayMarch(positionCS, positionWS, reflectDir, maxSampleCount, sampleStep, jitter);
        uvz.z *= ssrWeight;
        result = uvz;
    }
    return result;
}

float3 GetSSRUVZOtho(float4 positionCS, float3 positionWS, float3 reflectDir, half maxSampleCount, float sampleStep, half jitter)
{
    float3 uvz = SSRRayMarch(positionCS, positionWS, reflectDir, maxSampleCount, sampleStep, jitter);
    return uvz;
}

#endif