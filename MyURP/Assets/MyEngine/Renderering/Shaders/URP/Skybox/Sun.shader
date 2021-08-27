Shader "MyEngine/URP/Skybox/Sun"
{
    Properties
    {
        
    }

    HLSLINCLUDE

    #include "TOD_Base.hlsl"
    #include "TOD_Scattering.hlsl"

    struct v2f
    {
        float4 position : SV_POSITION;
        half3 tex : TEXCOORD0;
        float2 fogAtten : TEXCOORD1;
    };

    v2f vert(appdata_base v)
    {
        v2f o;

        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);

        float3 worldPos = mul(TOD_Object2World, v.vertex).xyz; 
        float3 skyPos = mul(TOD_World2Sky, worldPos).xyz;

        o.tex.xy = 2 * v.texcoord.xy - 1;
        o.tex.z = skyPos.y * 25;

        o.fogAtten = clamp(ComputeFogAtten(worldPos), 0.0, 1);

        return o;
    }

    half4 frag(v2f i): COLOR
    {
        half3 color = TOD_SunMeshColor;

        half dist = length(i.tex.xy);

         half sun = step(dist, 0.5) * TOD_SunMeshBrightness;

         half glow = smoothstep(0, 1, 1 - pow(dist, TOD_SunMeshContrast)) * saturate(TOD_SunMeshBrightness);

         color *= saturate(i.tex.z) * (sun + glow) * ( 1 - i.fogAtten.x);

         return half4(color, 0);
    }
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="AlphaTest+23" "RenderType"= "Background" "IgnoreProjector" = "True" "RenderPipeline"="UniversalPipeline" }
        

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            ZWrite Off
            ZTest LEqual
            Blend One One
            Fog { Mode Off }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }

    Fallback Off
}
