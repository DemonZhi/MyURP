Shader "MyEngine/URP/Skybox/Moon"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}    
    }

    HLSLINCLUDE

    #include "TOD_Base.hlsl"
    #include "TOD_Scattering.hlsl"

    uniform sampler2D _MainTex;

    CBUFFER_START(UnityPerMaterial)
    uniform float4 _MainTex_ST;
    CBUFFER_END

    struct v2f
    {
        float4 position : SV_POSITION;  
        half3 tex   :  TEXCOORD0;
        half3 normal : TEXCOORD1;
        float2 fogAtten : TEXCOORD2;
    };

    v2f vert(appdata_base v)
    {
        v2f o;
        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);

        o.normal = SafeNormalize_Half3(mul((float3x3)TOD_Object2World,v.normal));
        
        float3 worldPos = mul(TOD_Object2World, v.vertex).xyz;

        float3 skyPos = mul(TOD_World2Sky, worldPos).xyz;

        o.tex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

        o.tex.z = skyPos.y * 25;

        o.fogAtten = ComputeFogAtten(worldPos);

        return o;
    }

    half4 frag(v2f i): COLOR
    {
        half4 color = half4(TOD_MoonMeshColor, 0);
        half alpha = max(0, dot(i.normal, TOD_SunDirection));
        alpha = saturate(i.tex.z) * TOD_MoonMeshBrightness * pow(alpha, TOD_MoonMeshContrast);

        half3 maintex = tex2D(_MainTex, i.tex.xy).rgb;

        color.rgb *= maintex * alpha * (1 - i.fogAtten.x);

        return color;
    }
    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "Queue"="AlphaTest+24" 
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
            ENDHLSL
        }
    }

    Fallback Off
}
