#ifndef TOD_BASE_INCLUDED
#define TOD_BASE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata_base
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float4 texcoord : TEXCOORD;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct appdata_tan
{
    float4 vertex   : POSITION;
    float4 tangent  : TANGENT;
    float3 normal   : NORMAL;
    float4 texcoord : TEXCOORD;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct appdata_full
{
    float4 vertex   : POSITION;
    float4 tangent  : TANGENT;
    float3 normal   : NORMAL;
    float4 texcoord : TEXCOORD;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

uniform sampler2D TOD_BayerTexture;
uniform sampler2D TOD_CloudTexture;

uniform float4x4 TOD_World2Sky;
uniform float4x4 TOD_Sky2World;

uniform float3 TOD_SunLightColor;
uniform float3 TOD_MoonLightColor;

uniform float3 TOD_SunSkyColor;
uniform float3 TOD_MoonSkyColor;

uniform float3 TOD_SunMeshColor;
uniform float3 TOD_MoonMeshColor;

uniform float3 TOD_SunCloudColor;
uniform float3 TOD_MoonCloudColor;

uniform float3 TOD_GroundColor;
uniform float3 TOD_AmbientColor;

uniform float3 TOD_SunDirection;
uniform float3 TOD_MoonDirection;
uniform float3 TOD_LightDirection;

uniform float3 TOD_LocalSunDirection;
uniform float3 TOD_LocalMoonDirection;
uniform float3 TOD_LocalLightDirection;

uniform float TOD_Contrast;
uniform float TOD_Brightness;
uniform float TOD_AtmosphereFogMultiplier;

uniform float TOD_MoonHaloPower;
uniform float3 TOD_MoonHaloColor;

uniform float TOD_CloudOpacity;
uniform float TOD_CloudCoverage;
uniform float TOD_CloudSharpness;
uniform float TOD_CloudDensity;
uniform float TOD_CloudColoring;
uniform float TOD_CloudAttenuation;
uniform float TOD_CloudSaturation;
uniform float TOD_CloudScattering;
uniform float TOD_CloudBrightness;
uniform float TOD_CloudShadowScale;
uniform float3 TOD_CloudOffset;
uniform float3 TOD_CloudWind;
uniform float3 TOD_CloudSize;

uniform float TOD_CloudShadowCutoff;
uniform float TOD_CloudShadowFade;
uniform float TOD_CloudShadowIntensity;
uniform float TOD_CloudFogMultiplier;

uniform float TOD_StarSize;
uniform float TOD_StarBrightness;
uniform float TOD_StarVisbility;

uniform float TOD_SunMeshContrast;
uniform float TOD_SunMeshBrightness;

uniform float TOD_MoonMeshContrast;
uniform float TOD_MoonMeshBrightness;

uniform float4 TOD_ScatterDensity;

uniform float3 TOD_kBetaMie;
uniform float4 TOD_kSun;
uniform float4 TOD_k4PI;
uniform float4 TOD_kRadius;
uniform float4 TOD_kScale;

uniform float3 TOD_SunWorldPos;

#define TOD_TRANSFORM_VERT(vert) TransformObjectToHClip(vert)

// UV rotation matrix constructor
#define TOD_ROTATION_UV(angle) float2x2( cos(angle), -sin(angle), sin(angle), cos(angle) )

#define TOD_HRD2LDR(color) (1.0 - exp2( -TOD_Brightness * color))


#define TOD_GAMMA2LINEAR(color) (color * color)
#define TOD_LINEAR2GAMMA(color) sqrt(color)

#define TOD_Object2World unity_ObjectToWorld
#define TOD_World2Object unity_WorldToObject

// screen space adjust
#define TOD_UV(x, y) UnityStereoScreenSpaceUVAdjust(x,y)

// stereo output
#define TOD_VERTEX_OUTPUT_STEREO UNITY_VERTEX_OUTPUT_STEREO
#define TOD_INITIALIZE_VERTEX_OUTPUT_STEREO(o) UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(O)

#define TOD_INSTANCE_ID UNITY_VERTEX_INPUT_INSTANCE_ID
#define TOD_SETUP_INSTANCE_ID(o) UNITY_SETUP_INSTANCE_ID(o)

#endif
