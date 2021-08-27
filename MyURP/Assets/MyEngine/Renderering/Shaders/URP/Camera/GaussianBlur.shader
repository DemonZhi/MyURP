Shader "MyEngine/URP/Camera/GaussianBlur"
{
    Properties
    {
        _MainTex ("_MainTex", 2D) = "white" {}
        _GaussianBlurBlend("_GaussianBlurBlend", Range(0.0, 1.0)) = 1
        _GaussianBlurOffset("_GaussianBlurOffset", Vector) = (1, 1, 1, 1)
    }

    HLSLINCLUDE
    // URP
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
    
    TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
    half _GaussianBlurBlend;
    half4 _GaussianBlurOffset;

    half4 Frag (Varyings input) : SV_Target
    {
        // sample the texture
        half4 blurColor = 0;
        half2 off1 = float2(_GaussianBlurOffset.x, _GaussianBlurOffset.y);
        half2 off2 = float2(_GaussianBlurOffset.z, _GaussianBlurOffset.w);

        half scale = smoothstep(_GaussianBlurBlend, 1, 1 - input.uv.y);
        off1 *= scale;
        off2 *= scale;

        blurColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * 0.2270270270;
        blurColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + off1) * 0.3162162162;
        blurColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv - off1) * 0.3162162162;
        blurColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv + off2) * 0.0702702703;
        blurColor += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv - off2) * 0.0702702703;
       
        return blurColor;
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
            Name "GaussianBlur"
            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
