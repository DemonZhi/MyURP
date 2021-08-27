Shader "MyEngine/URP/Camera/RadialBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RadialBlurWidth("_RadialBlurWidth", Range(0.0, 1.0)) = 0.2
        _RadialBlurStrength("_RadialBlurStrength", Range(0.0, 5.0)) = 1
    }

    HLSLINCLUDE
    // URP
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    
    TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
    half _RadialBlurWidth;
    half _RadialBlurStrength;

    half4 Frag (Varyings input) : SV_Target
    {
        // sample the texture
        half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
        half2 dir = half2(0.5, 0.5) - input.uv.xy;
        half dist = length(dir);
        dir *= rcp(dist);

        const half weights[10] = 
        {
            -0.08, -0.05, -0.03, -0.02, -0.01, 0.01, 0.02, 0.03, 0.05,0.08
        };

        half4 sum = color;

        for(int i = 0; i < 10; ++i)
        {
            sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy + dir * weights[i] * _RadialBlurWidth);
        }

        sum *= rcp(11);
       
        return lerp(color, sum, saturate(dist * _RadialBlurStrength));
    }

    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 100
        ZTest Always
        ZWrite Off
        Cull Off
        Pass
        {
            Name "Radial Blur"
            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
