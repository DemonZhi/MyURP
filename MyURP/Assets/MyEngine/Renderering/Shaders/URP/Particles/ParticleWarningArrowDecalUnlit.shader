Shader "MyEngine/URP/Particles/ParticleWarningArrowDecalUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexOffsetX("_MainTexOffsetX", Float) = 0.0
        _MainTexOffsetY("_MainTexOffsetY", Float) = 0.0

        _Color("_Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorFactor("Color Factor", Float) = 1.0
        _Poser("Poser", Range(1.0, 20.0)) = 1.0
        _Gray("Gray", Range(0.0, 2.0)) = 0.0
        _BlackAlpha("BlackAlpha", Range(0.0, 1.0)) = 0.0
        _Alpha("Alpha", Range(0.0,100.0)) = 1.0

        [Header(Flow)]
        _FlowColor("Flow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Duration("Duration", Range(0.0, 1.0)) = 0.0



        [Toggle(_ALPHATEST_ON)]
        _AlphaClip("AlphaClip", Float) = 0.0
        _Cutoff("Cut Off", Range(0.0, 1.0)) = 0.5

        [keywordEnum(Alpha,Additive)]
        _AlphaMode("mode", Float) = 1.0
        _SrcBlend("SrcBlend", Float) = 1.0
        _DstBlend("DstBlend",Float) = 0.0
        _ZWrite("ZWrite",Float) = 0.0        

        [keywordEnum(Off,Front,Back)]
        _Cull("Cull", Float) = 2.0
        
        _QueueOffset(" _QueueOffset", Float) = 0.0
        _ProjectionPositionOffsetZ("ProjectionPositionOffsetZ", Float) = 0.0

        _StencilComp("Stencil", Float) = 8.0
        
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "DisableBatching" = "True"
        }

        Blend [_SrcBlend][_DstBlend]
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest Always

        Stencil
        {
            Ref 255
            Comp notequal
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #define DECAL 1
            #define WARNINGARROW 1

            #pragma vertex vert
            #pragma fragment frag

            #include "./Includes/ParticleUnlit_Base.hlsl"

            ENDHLSL
           
        }
    }
    
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ParticleShaderGUI"
}
