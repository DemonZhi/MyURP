Shader "MyEngine/URP/Particles/ParticleDissolveNoiseUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexOffsetX("_MainTexOffsetX", Float) = 0.0
        _MainTexOffsetY("_MainTexOffsetY", Float) = 0.0
    
        [Toggle(_VERTEXOFFSET_ON)]
        _VertexOffsetEnable ("_VertexOffsetEnable", Float) = 0
        _VertexOffsetTex("_VertexOffsetTex", 2D) =  "white" {}
        _VertexOffsetTexU("_VertexOffsetTexU", Float) = 0.0
        _VertexOffsetTexV("_VertexOffsetTexV", Float) = 0.0
        _VertexOffsetIndensity("_VertexOffsetIndensity", Vector) =(0.0, 0.0, 1.0, 1.0)

        _Color("_Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorFactor("Color Factor", Float) = 1.0
        _Poser("Poser", Range(1.0, 20.0)) = 1.0
        _Gray("Gray", Range(0.0, 2.0)) = 0.0
        _BlackAlpha("BlackAlpha", Range(0.0, 1.0)) = 0.0
        _Alpha("Alpha", Range(0.0,100.0)) = 1.0

        _MaskTex ("_MaskTex", 2D) = "white" {}
        _MaskOffsetX("_MaskOffsetX", Float) = 0.0
        _MaskOffsetY("_MaskOffsetY", Float) = 0.0

        _DistortionMap ("DistortionMap", 2D) = "black" {}
        _DistortionSpeed("_DistortionSpeed", Vector) = (0.0, 0.0, 1.0, 1.0)
    
        _DistortionMaskMap ("_MaskTex", 2D) = "white" {}
        _DistortionMaskU("_DistortionMaskU", Float) = 0.0
        _DistortionMaskV("_DistortionMaskV", Float) = 0.0

        [keywordEnum(Dissolve, VertexAlpha_Dissolve,VertexAlpha_DissolveAlpha)]
        _DissolveType("DissolveType", Int) = 0
        _Dissolve("_Dissolve", Range(0.0, 2.0)) = 0.0
        _DissolveMap("_DissolveMap", 2D) = "white" {}
        _DissolveOffsetX("_DissolveOffsetX", Float) = 0.0
        _DissolveOffsetY("_DissolveOffsetY", Float) = 0.0      

        _DissolveMaskMap ("DistortionMap", 2D) = "black" {}
        _DissolveMaskMapUSpeed("DistortionOffsetX", Float) = 0.0
        _DissolveMaskMapVSpeed("DistortionOffsetY", Float) = 0.0

        _DissolveEdgeColorEnable("_DissolveEdgeColorEnable", Float) = 0
        _EdgeColor("_EdgeColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _EdgeColorFactor("_EdgeColorFactor", Range(1.0, 100.0)) = 1.0
        _EdgeWidth("_EdgeWidth", Range(1.0, 1.0)) = 0.02
        _EdgeWidthMid("_EdgeWidthMid", Range(0.0, 1.0)) = 0.01
        _EdgeWidthInner("_EdgeWidthInner", Range(0.0, 1.0)) = 0.01
        _EdgeBlack("_EdgeBlack", Range(0.0, 1.0)) = 0.0

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
            #define BLACKALPHA 1
            #define POWCOLOR 1
            #define GRAYCOLOR 1

            #define MASK 1
            #define NOISE 1
            #define NOISEMASK 1
            #define DISSOLVE 1
            #define DISSOLVEMASK 1

            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ALPHATEST_ON
            #pragma multi_compile UIMODE_OFF UIMODE_ON
            #pragma multi_compile _ _SOFTPARTICLES_ON
            #pragma multi_compile _ _UV_ROTATE_ON _UV_RADIAL_ON
            #pragma multi_compile _ _EFFECTFOG_ON
            #pragma multi_compile _ _VERTEXOFFSET_ON
            #pragma multi_compile_local_fragment _ _AMBIENTLIGHT_ON

            #include "./Includes/ParticleUnlit_Base.hlsl"

            ENDHLSL
           
        }
    }
    
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ParticleShaderGUI"
}
