Shader "MyEngine/URP/Skybox/Skybox"
{
    Properties
    {
        
    }

    HLSLINCLUDE

    #include "TOD_Base.hlsl"
    #define TOD_SCATTERING_MIE 0
    #include "TOD_Scattering.hlsl"

    struct v2f
    {
        float4 position : SV_POSITION;                
        float3 color : TEXCOORD0;
    };

    v2f vert(appdata_base v)
    {
        v2f o;

        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);
        float3 vertex = SafeNormalize_Half3( mul((float3x3)TOD_World2Sky, mul((float3x3)TOD_Object2World, v.vertex.xyz)));
        
        float a = pow(1,2);
        o.color = (vertex.y < 0) ? pow( abs(TOD_GroundColor), TOD_Contrast) : ScatteringColor(vertex.xyz).rgb;

        #if !TOD_OUTPUT_HDR
            o.color = TOD_HDR2LDR(o.color);
        #endif
        
        #if !TOD_OUTPUT_LINEAR
            o.color = TOD_LINEAR2GAMMA(o.color);
        #endif

        return o;
    }

    half4 frag(v2f i): COLOR
    {
        return half4(i.color, 1);
    }
    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "Queue"="AlphaTest+20" 
            "RenderType"= "Background"    
            "PreviewType" = "Skybox"      
            "RenderPipeline"="UniversalPipeline" 
        }
        

        Pass
        {
            Tags{ "LightMode" = "UniversalForward" }

            ZWrite Off
            Cull Off
           

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag        
            #pragma multi_compile _ TOD_OUTPUT_HDR
            #pragma multi_compile _ TOD_OUTPUT_LINEAR
            ENDHLSL
        }
    }

    Fallback Off
}
