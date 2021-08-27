Shader "MyEngine/URP/Skybox/Stars"
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
        half3 color : COLOR;
        half3 tex : TEXCOORD0;
        float2 fogAtten : TEXCOORD1;
    };

    v2f vert(appdata_full v)
    {
        v2f o;

        float tanFovHalf = 1.0 / max(0.1, UNITY_MATRIX_P[0][0]);
        float radius = 4.0 * tanFovHalf / _ScreenParams.x;
        float alpha = TOD_StarBrightness * TOD_StarVisibility * 0.00001 * v.color.a / (radius * radius);
        float size = TOD_StarSize * radius;

        float3 u_vec = v.tangent.xyz;
        float3 v_vec = cross(v.normal, v.tangent.xyz);

        float u_fac = v.texcoord.x - 0.5;
        float v_fac = v.texcoord.y - 0.5;

        v.vertex.xyz -= u_vec * u_fac * size;
        v.vertex.xyz -= u_vec * u_fac * size;

        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);

        float3 worldPos = mul(TOD_Object2World, v.vertex).xyz;
        float3 skyPos = mul(TOD_World2Sky, worldPos).xyz;
      
        o.tex.xy = 2 * v.texcoord.xy - 1 ;
        o.tex.z = skyPos.y * 25;

        o.color = half3(alpha, alpha, alpha);

        #if !TOD_OUTPUT_LINEAR
            o.color = TOD_LINEAR2GAMMA(o.color);
        #endif

        o.fogAtten = ComputeFogAtten(worldPos);
    
        return o;
    }

    half4 frag(v2f i): COLOR
    {
        half dist = length(i.tex.xy);
        half spot = saturate(1 - dist);
        half alpha = saturate(i.tex.z) * spot * (1 - i.fogAtten.x);
         return half4(i.color * alpha, 0);
    }
    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "Queue"="AlphaTest+23" 
            "RenderType"= "Background"          
            "RenderPipeline"="UniversalPipeline" 
        }
        

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            ZWrite Off
            ZTest LEqual
            Blend One One
           

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_complie _ TOD_OUTPUT_LINEAR
            ENDHLSL
        }
    }

    Fallback Off
}
