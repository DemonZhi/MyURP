Shader "MyEngine/URP/Skybox/Atomsphere"
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
        float2 fogAtten : TEXCOORD0;
        #if TOD_SCATTERING_PER_PIXEL
            float3 inscatter : TEXCOORD1;
            float3 outscatter : TEXCOORD2;
            float3 viewDir : TEXCOORD3;
        #else
            float4 color : TEXCOORD1;
        #endif
      
    };

    float4 Adjust(float4 color)
    {
        #if !TOD_OUTPUT_HDR
            color = TOD_HDR2LDR(color);
        #endif

        #if !TOD_OUTPUT_LINEAR
            color = TOD_LINEAR2GAMMA(color);
        #endif
        return color;
    }

    v2f vert(appdata_base v)
    {
        v2f o;
        o.position = TOD_TRANSFORM_VERT(v.vertex.xyz);

        float3 vertnorm = SafeNormalize_Half3(v.vertex.xyz);

        #if TOD_SCATTERING_PER_PIXEL
            o.viewDir = vertnorm;
            ScatteringCoefficients(o.viewDir, o.inscatter, o.outscatter);
        #else
            o.color = Adjust(ScatteringColor(vertnorm));
        #endif
            float3 worldPos = mul(TOD_Object2World, v.vertex).xyz;
            o.fogAtten = ComputeFogAtten(worldPos) * TOD_AtmosphereFogMultiplier;

        return o;
    }

    half4 frag(v2f i): COLOR
    {
        #if TOD_SCATTERING_PER_PIXEL
float4 color = Adjust(ScatteringColor(SafeNormalize_Half3(i.viewDir), i));
        #else
            float4 color  = i.color;
        #endif

        color.rgb = ApplyFog(color.rgb , i.fogAtten);

        return float4(color.rgb , 0);
    }
    ENDHLSL

    SubShader
    {
        Tags 
        { 
            "Queue"="AlphaTest+20" 
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
            #pragma multi_compile _ TOD_OUTPUT_HDR
            #pragma multi_compile _ TOD_OUTPUT_LINEAR
            #pragma multi_compile _ TOD_SCATTERING_PER_PIXEL
            ENDHLSL
        }
    }

    Fallback Off
}
