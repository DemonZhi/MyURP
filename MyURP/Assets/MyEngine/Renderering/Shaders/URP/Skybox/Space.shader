Shader "MyEngine/URP/Skybox/Space"
{
    Properties
    {
        _CubeTex("Cube Tex", Cube) = "black" {}
        _Brightness("_Brightness", float) = 0
    }

    HLSLINCLUDE

    #include "TOD_Base.hlsl"
    #include "../Base/Includes/MyEngine_Common.hlsl"

    uniform samplerCUBE _CubeTex;

    CBUFFER_START(UnityPerMaterial)
    uniform float _Brightness;
    CBUFFER_END

    struct v2f
    {
        float4 position : SV_POSITION;                
        float4 viewdir : TEXCOORD0;
    };

    v2f vert(appdata_base v)
    {
        v2f o;
        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);
        float3 vertnorm = SafeNormalize_Half3(v.vertex.xyz);
        float3 worldNormal = SafeNormalize_Half3( mul((float3x3)TOD_Object2World, vertnorm));

        o.viewdir.xyz = vertnorm;
        o.viewdir.w = saturate(_Brightness * TOD_StarVisibility * worldNormal.y);

        return o;
    }

    half4 frag(v2f i): COLOR
    {
        half3 color = texCUBE(_CubeTex, i.viewdir.xyz).rgb * i.viewdir.w;
         return half4(color, 0);
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
            ENDHLSL
        }
    }

    Fallback Off
}
