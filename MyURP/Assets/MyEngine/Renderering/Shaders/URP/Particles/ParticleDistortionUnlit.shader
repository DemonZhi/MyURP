Shader "MyEngine/URP/Particles/ParticleDistortionUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTexOffsetX("_MainTexOffsetX", Float) = 0.0
        _MainTexOffsetY("_MainTexOffsetY", Float) = 0.0

        _Color("_Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ColorFactor("Color Factor", Float) = 1.0

        _Alpha("Alpha", Range(0.0,100.0)) = 1.0
        _DistortionIntensity("_DistortionIntensity", Range(0.0,1.0)) = 1.0
        
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
            "LightMode" = "GrabPass"
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
            #define PARTICLEDISTORTION 1
            #define MASK 1

            #pragma vertex vert
            #pragma fragment frag

           
            #pragma multi_compile UIMODE_OFF UIMODE_ON
            #pragma multi_compile _ _SOFTPARTICLES_ON
            #pragma multi_compile _ _UV_ROTATE_ON _UV_RADIAL_ON



            #include "./Includes/ParticleUnlit_Base.hlsl"

            ENDHLSL
           
        }
    }
    
    Fallback "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "ParticleShaderGUI"
}
