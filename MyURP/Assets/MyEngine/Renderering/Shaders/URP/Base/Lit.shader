Shader "MyEngine/URP/Lit"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] _WorkflowMode("WorkflowMode", Float) = 1.0

        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _MetallicScale("Metallic Scale", Range(0, 2)) = 1
        _RoughnessScale("Roughness Scale",  Range(0, 2)) = 1

        _MetallicGlossMap("Metallic GlossMap", 2D) = "white" {}

        _NormalMap("Normal Map", 2D) = "white" {}

        _EmissionColor("Color", Color) = (0, 0, 0)
        _EmissionMap("Emission", 2D) = "white" {}

        _EmissionIntensity("Emission  Intensity", Range(0, 8)) = 1
        _CubemapEmissionCubemap("CubeMap Emission Cubemap", Cube) = "" {}

        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__Clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__Src", Float) = 1.0
        [HideInInspector] _DstBlend("__Dst", Float) = 0.0
        [HideInInspector] _Zwrite("__Zw", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        _ReceiveShadows("Receive Shadows", Float) = 1.0

        [HideInInspector] _QueueOffset("_Queue Offset", Float) = 0.0

        [HideInInspector] _MainTex("_MainTex", 2D ) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"= "UniversalPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{ "LightMode" = "UniversalForward" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_Zwrite]
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            //#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local_fragment _EMISSION
            //#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            //#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature_local_fragment _OCCLUSIONMAP
            //#pragma shader_feature_local _PARALLAXMAP
            //#pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            //#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            //#pragma shader_feature_local_fragment _SPECULAR_SETUP
            //#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #define LIGHTMAP_SHADOW_MIXING 1
           
            //#pragma multi_compile _ SHADOWS_SHADOWMASK
            #define SHADOWS_SHADOWMASK 1

            // -------------------------------------
            // Unity defined keywords
            //#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _MYENGINE_WET
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            //#pragma multi_compile_fog NECESSERY

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            //--------------------------------------
            // MyEngine Global Setting
            #pragma multi_compile _ _MYENGINE_QUALITY_HIGH
            #include "../Base/Includes/MyEngine_Keywords.hlsl"

            #pragma vertex vert
            #pragma fragment frag
           
            #include "../Base/Includes/MyEngine_Debug.hlsl"
            #include "../Base/Includes/Lit_Base.hlsl"

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);                

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                #if defined(_NORMALMAP) && defined(_USE_NORMALMAP)
                    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
                    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
                    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
                #else
                    output.normalWS = SafeNormalize_Half3(normalInput.normalWS);
                    output.viewDirWS = viewDirWS;
                #endif

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                output.fogFactorAndVertexLight = half4(0, vertexLight);
                output.positionWS = vertexInput.positionWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                
                output.fogAtten = ComputeFogAtten(vertexInput.positionWS);
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {              
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                #if !defined(SHADER_QUALITY_LOW)
                    #if defined(LOD_FADE_CROSSFADE)
                        LODDitheringTransition(input.positionCS.xy, unity_LODFade.x);
                    #endif
                #endif

                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input, surfaceData);

                
                
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

                #if defined(_EMISSION)
                    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
                    half3 cubemapEmission = SAMPLE_TEXTURECUBE(_CubemapEmissionCubemap, sampler_CubemapEmissionCubemap, reflectVector).rgb;
                    surfaceData.emission *= cubemapEmission;
                #endif

                #if defined(_MYENGINE_WET) && defined(_SCENE_WET)
                    #if defined(_NORMALMAP) && defined(_USE_NORMALMAP)
                    half3 wetNormalTS = GetWetNormalTS(inputData.positionWS, inputData.normalWS, input.positionCS);
                    surfaceData.normalTS = BlendNormal(surfaceData.normalTS, wetNormalTS);
                    inputData.normalWS = TransformTangentToWorld(surfaceData.normalTS, half3x3( input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                    inputData.normalWS = SafeNormalize_Half3(inputData.normalWS);
                    surfaceData.albedo = SampleAlbedoAlpha(input.uv + wetNormalTS.xy * _WetRefractionScale, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)) * _BaseColor.rgb;
                    #endif
                    WetBRDF(surfaceData.metallic, surfaceData.albedo, surfaceData.smoothness);
                #endif
//return half4(surfaceData.occlusion.xxx,1);
                #if defined(_MYENGINE_DEBUG)
                    return MyEngineDebug(surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, input.vertexColor);
                #endif

                half4 color = UniversalWrappedFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness,surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);
                
                color.rgb = ApplyFog(color.rgb, input.fogAtten);
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            

            #pragma vertex vert
            #pragma fragment frag

            #include "./Includes/Lit_Base.hlsl"

            float3 _LightDirection;
            
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE)
                #endif

                output.positionCS = positionCS;
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {

                #if !defined(SHADER_QUALITY_LOW)
                    #if defined(LOD_FADE_CROSSFADE)
                        LODDitheringTransition(input.positionCS.xy, unity_LODFade.x);
                    #endif
                #endif
                Alpha( SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor,_Cutoff );
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On            
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            

            #pragma vertex vert
            #pragma fragment frag

            #include "./Includes/Lit_Base.hlsl"            
            
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if !defined(SHADER_QUALITY_LOW)
                    #if defined(LOD_FADE_CROSSFADE)
                        LODDitheringTransition(input.positionCS.xy, unity_LODFade.x);
                    #endif
                #endif
                Alpha( SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor,_Cutoff );
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On                        
            Cull[_Cull]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local _NORMALMAP

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            

            #pragma vertex vert
            #pragma fragment frag

            #include "./Includes/Lit_Base.hlsl"
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                output.uv         = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS.xyz = SafeNormalize_Half3(normalInput.normalWS);

                return output;
            }

            float4 frag(Varyings input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
            }
            ENDHLSL
        }

                // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
            #include "./Includes/Lit_Base.hlsl"

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                
                output.positionCS = MetaVertexPosition(input.positionOS, input.lightmapUV, input.lightmapUV, unity_LightmapST, unity_DynamicLightmapST);
                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                return output;
            }

            half4 frag (Varyings input) : SV_Target
            {
                SurfaceData surfaceData;
                InitializeStandardLitSurfaceData(input, surfaceData);

                #if defined(_EMISSION)
                    InputData inputData;
                    InitializeInputData(input, surfaceData.normalTS, inputData);

                    half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
                    half3 cubemapEmission = SAMPLE_TEXTURECUBE(_CubemapEmissionCubemap, sampler_CubemapEmissionCubemap, reflectVector).rgb;
                    surfaceData.emission *= cubemapEmission;
                #endif

                BRDFData brdfData;
                InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

                MetaInput metaInput;
                metaInput.Albedo = brdfData.diffuse +  brdfData.specular * brdfData.roughness * 0.5;
                metaInput.SpecularColor = surfaceData.specular;
                metaInput.Emission = surfaceData.emission;

                return MetaFragment(metaInput);
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"

}
