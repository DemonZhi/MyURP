#ifndef TOD_CLOUDS_INCLUDED
#define TOD_CLOUDS_INCLUDED

uniform sampler2D _CloudDensityMap;
uniform float4 _CloudDensityMap_ST;
half _CloudShadowScale;
half _CloudShadowCutoff;
half _CloudShadowFadeEnd;

inline float3 CloudPosition(float3 viewDir,float3 Offset)
{
    float mult = 1.0 / lerp(0.1, 1.0, viewDir.y);
    return (float3 (viewDir.x * mult + offset.x, 0, viewDir.z * mult + offset.z)) / TOD_CloudSize;
}

inline float4 CloudUV(float3 viewDir, float3 offset)
{
    float cloudPos = CloudPosition(viewDir, offset);
    float uv1 = cloudPos.xz + TOD_CloudOffset.XZ + TOD_CloudWind.xz;
    float uv2 = mul(TOD_ROTATION_UV(radians(10.0)), cloudPos.xz )  + TOD_CloudOffset.XZ + TOD_CloudWind.xz;
    return float4(uv1.x, uv1.y, uv2.x, uv2.y);
}

inline float4 CloudUV(float3 viewDir)
{
    return CloudUV(viewDir, 0);
}

inline float3 CloudColor(float3 viewDir, float3 lightDir)
{
    float lerpValue = saturate(1 + 4 * lightDir.y) * saturate(dot(viewDir, lightDir) + 1.25 );
    float3 cloudColor = lerp(TOD_MoonCloudColor, TOD_SunCloudColor, lerpValue);
    return TOD_Brightness * cloudColor;
}

inline half3 CloudLayerDensity(sampler2D densityTex, float4 uv, float3 viewDir)
{
    half3 density = 0;
#if TOD_CLOUDS_DENSITY
    const float thickness = 0.1;
    const half4 stepoffset = half4(0.0, 1.0, 2.0, 3.0) * thickness;
    const half4 sumy = half4(0.5, 0.25, 0.125, 0.0625) / half(1, 2, 3, 4);
    const half4 sumz = half4(0.5, 0.25, 0.125, 0.0625);

    half2 uv1 = uv.xy + viewDir.xz * stepoffset.x;
    half2 uv2 = uv.zw + viewDir.xz * stepoffset.y;
    half2 uv3 = uv.xy + viewDir.xz * stepoffset.z;
    half2 uv4 = uv.zw + viewDir.xz * stepoffset.w;

    half4 n1 = tex2D(densityTex, uv1);
    half4 n2 = tex2D(densityTex, uv2);
    half4 n3 = tex2D(densityTex, uv3);
    half4 n4 = tex2D(densityTex, uv4);

    //Noise when marching in up direction
    half4 ny = half4(n1.r, n1.g + n2.g, n1.b + n2.b + n3.b, n1.a + n2.a + n3.a + n4.a );

    //Noise when marching in view direction
    half4 nz = half4(n1.r, n2.g, n3.b, n4.a);

    //density when marching in up direction
    density.y += dot(nz, sumy);

    //density when marching in view direction
    density.z += dot(nz, sumz);

    //Courage
    half2 stepA = TOD_CloudCoverage;
    half2 stepB = TOD_CloudCoverage + TOD_CloudSharpness;
    half2 stepC = TOD_CloudDensity;
    density.yz = smoothstep(stepA, stepB, density.yz) + saturate(density.yz - stepB) * stepC;

    //Opacity
    density.x = saturate(density.z);

    //shading
    density.yz *= half2(TOD_CloudAttenuation, TOD_CloudSaturation);

    // Remap
    density.yz = 1.0 - exp2( - density.yz);

#else
    
    half4 n = tex2D(densityTex, uv.xy);

    //density when marching in up direction
    density.y += n.r;
    //density when marching in up direction
    density.z += n.r;

    //Coverage
    density.yz = ( density.yz - TOD_CloudCoverage ) * half2(TOD_CloudAttenuation, TOD_CloudDensity);

    //Opacity
    density.x = saturate(density.z);

#endif

    return density;

}


inline half CloudShadow(sampler2D densityTex, float4 uv)
{
    return CloudLayerDensity(densityTex, uv, float3(0,1,0)).x;
}

inline half3 CloudBillboardDensity(sampler2D densityTex, float2 uv, float3 viewDir)
{
    half3 density = 0;
    half4 tex = tex2D(densityTex, uv.xy);

    density.y = tex.a;

#if TOD_CLOUDS_DENSITY
    density.z = lerp( lerp(tex.r, tex.g, saturate(viewDir.x)), tex.b, saturate(-viewDir.x));
#else
    density.z = tex.r;
#endif

    //Opacity
    density.x = saturate(density.z);

    //shading
    density.y *= TOD_CloudAttenuation;

    return density;
}

inline half SGCloudShadow(float3 worldPos)
{

#if _SGENGINE_CLOUDSHADOW
    worldPos.x *= _CloudShadowScale;
    worldPos.z *= _CloudShadowScale;

    float3 skyPos = mul((float3x3)TOD_World2Sky, worldPos);
    float4 cloudUV = CloudUV(TOD_LocalLightDirection, skyPos);

    half cloudShadowAtten = 1 - TOD_CloudOpacity * CloudLayerDensity(_CloudDensityMap, cloudUV, TOD_LocalLightDirection).x * TOD_CloudShadowIntensity;
    cloudShadowAtten = smoothstep(_CloudShadowCutoff, _CloudShadowFadeEnd, saturate(cloudShadowAtten));

    return cloudShadowAtten;

#else
    return 1;
#endif

}

#endif