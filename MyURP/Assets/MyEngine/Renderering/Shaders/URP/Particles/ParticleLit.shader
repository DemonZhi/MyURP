Shader "MyEngine/URP/Particles/ParticleLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexOffsetX("_MainTexOffsetX", Float) = 0.0
        _MainTexOffsetY("_MainTexOffsetY", Float) = 0.0

        _Metallic0("Metallic0", Float) = 1
		_Metallic("Metallic", Float) = 6
		_Gloss0("Gloss0", Float) = 0
		_Gloss("Gloss", Float) = 1

        _Color("_Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorFactor("Color Factor", Float) = 1.0
        _Poser("Poser", Range(1.0, 20.0)) = 1.0
        _Gray("Gray", Range(0.0, 2.0)) = 0.0
        _BlackAlpha("BlackAlpha", Range(0.0, 1.0)) = 0.0
        _Alpha("Alpha", Range(0.0,100.0)) = 1.0

        _NormalTex ("_NormalTex", 2D) = "white" {}
        _NormalOffsetU("_NormalOffsetU", Float) = 0.0
        _NormalOffsetV("_NormalOffsetV", Float) = 0.0
        _NormalScale("_NormalScale", Float) = 1.0

        _NormalMaskTex ("_NormalMaskTex", 2D) = "white" {}
        _NormalMaskOffsetU("_NormalMaskOffsetU", Float) = 0.0
        _NormalMaskOffsetV("_NormalMaskOffsetV", Float) = 0.0
        _NormalMaskOffset ("_NormalMaskOffset", Float) = 0.0

        [Toggle(_EFFECTFOG_ON)]
        _FogEnable("Fog Enable", Float) = 0.0
        _Fog("Fog", Range(0.0, 1.0 )) = 0.0

        [keywordEnum(Dissolve, VertexAlpha_Dissolve,VertexAlpha_DissolveAlpha)]
        _DissolveType("DissolveType", Int) = 0
        _Dissolve("_Dissolve", Range(0.0, 2.0)) = 0.0
        _DissolveMap("_DissolveMap", 2D) = "white" {}
        _DissolveOffsetX("_DissolveOffsetX", Float) = 0.0
        _DissolveOffsetY("_DissolveOffsetY", Float) = 0.0      

        _DissolveEdgeColorEnable("_DissolveEdgeColorEnable", Float) = 0
        _EdgeColor("_EdgeColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _EdgeColorFactor("_EdgeColorFactor", Range(1.0, 100.0)) = 1.0
        _EdgeWidth("_EdgeWidth", Range(1.0, 1.0)) = 0.02
        _EdgeWidthMid("_EdgeWidthMid", Range(0.0, 1.0)) = 0.01
        _EdgeWidthInner("_EdgeWidthInner", Range(0.0, 1.0)) = 0.01
        _EdgeBlack("_EdgeBlack", Range(0.0, 1.0)) = 0.0

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
            #define BLACKALPHA 1
            #define POWCOLOR 1
            #define GRAYCOLOR 1
            #define PARTICLELIT 1
            #define NORMALMASK 1
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile UIMODE_OFF UIMODE_ON
            #pragma multi_compile _ _SOFTPARTICLES_ON
            #pragma multi_compile _ _UV_ROTATE_ON _UV_RADIAL_ON
            #pragma multi_compile _ _EFFECTFOG_ON
            #pragma multi_compile_local_fragment _ _AMBIENTLIGHT_ON
            #pragma shader_feature_local _NORMALMAP

            #include "./Includes/ParticleLit_Base.hlsl"

            ENDHLSL
           
        }
    }
    
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ParticleShaderGUI"
}