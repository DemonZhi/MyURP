Shader "MyEngine/URP/Particles/ParticleWaveUnlit"
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


        _FlagWaveSpeed("_FlagWaveSpeed", Range(0,10)) = 3.0
        _FlagWaveFrequencyScale("_FlagWaveFrequencyScale", Range(0,10)) = 1.0
        _FlagWaveScale("_FlagWaveScale", Vector) = (0.3, 0.1, 0.3, 0.0)       
        _FlagWaveLengthOffset("_FlagWaveLengthOffset", Float) = -0.1
        _FlagWaveWindScale("_FlagWaveWindScale", Vector) = (1.0, 1.0, 1.0, 1.0)

        [Toggle(_VERTEXOFFSET_ON)]
        _VertexOffsetEnable ("_VertexOffsetEnable", Float) = 0
        _VertexOffsetTex ("_VertexOffsetTex", 2D) = "white" {}
        _VertexOffsetTexU("_VertexOffsetTexU", Float) = 0.1
        _VertexOffsetTexV("_VertexOffsetTexV", Float) = 0.1
        _VertexOffsetIndensity("_VertexOffsetIndensity", Vector) = (1.0, 1.0, 1.0, 1.0)

        [Toggle(_EFFECTFOG_ON)]
        _FogEnable("Fog Enable", Float) = 0.0
        _Fog("Fog", Range(0.0, 1.0 )) = 0.0

        [Toggle(_AMBIENTLIGHT_ON)]
        _Ambienting("Ambient Lighting", Float) = 0.0
        _AmbientingIntensity("Ambient Lighting Intensity", Range(0, 10)) = 0.0

        [Toggle(_SOFTPARTICLES_ON)]
        _SoftParticlesEnable("_SoftParticlesEnable",Float) = 0.0
        _SoftParticlesNearFadeDistance("_SoftParticlesNearFadeDistance",Float) = 0.0
        _SoftParticlesFarFadeDistance("_SoftParticlesFarFadeDistance",Float) = 0.0
        _SoftParticlesFadeParams("_SoftParticlesFadeParams",Float) = 0.0

        [Toggle(UV_ROTATE_ON)]
        _UVRotateEnabled("UV Rotate Enable", Float) = 0.0
        _UVRotate("UV Rotate", Float) = 0.0

        [Toggle(UV_RADIAL_ON)]
        _UVRadialEnabled("UV Rotate Enable", Float) = 0.0

        _ClipRect("Clip Rect", vector) = (0.0, 0.0, 0.0, 0.0)

        [Toggle(_ALPHATEST_ON)]
        _AlphaClip("AlphaClip", Float) = 0.0
        _Cutoff("Cut Off", Range(0.0, 1.0)) = 0.5

        [keywordEnum(Alpha,Additive)]
        _Mode("mode", Float) = 1.0
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
        }

        Blend[_SrcBlend][_DstBlend]
        Cull[_Cull]
        ZWrite[_ZWrite]

        Stencil
        {
            Ref 255
            Comp [_StencilComp]
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #define MAINTEX_UV_SCROLL 1
            #define PARTICLE_WAVE 1
            #define BLACKALPHA 1
            #define POWCOLOR 1
            #define GRAYCOLOR 1
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile UIMODE_OFF UIMODE_ON
            #pragma multi_compile _ _SOFTPARTICLES_ON
            #pragma multi_compile _ _UV_ROTATE_ON _UV_RADIAL_ON
            #pragma multi_compile _ _EFFECTFOG_ON
            #pragma multi_compile_local_fragment _ _AMBIENTLIGHT_ON

            #include "./Includes/ParticleUnlit_Base.hlsl"

            ENDHLSL
           
        }
    }
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ParticleShaderGUI"
}
