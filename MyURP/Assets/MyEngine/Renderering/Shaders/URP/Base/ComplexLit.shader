Shader "MyEngine/URP/ComplexLit"
{
    Properties
    {
        // Specular vs Metallic workflow
        [HideInInspector] _WorkflowMode("WorkflowMode", Float) = 1.0

        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        [Toggle(_TOPCOVER)]
        _TopEnable("Top Enable", Float) = 0;
        _TopMap("Top Map", 2D) = 0;
        _TopColor("Top Color", Color) = (1, 1, 1, 0)
        _TopNoiseMap("_TopNoiseMap", 2D) = "white" {}
        _TopBumpMap("_TopBumpMap", 2D) = "white" {}
        _TopOffset("_TopOffset", Range(-1.0, 1.0)) = 0.25
        _TopAOOffset("_TopAOOffset", Range(0.0, 16.0)) = 1.0
        _TopContrast("_TopContrast", Range(0.0, 2.0)) = 1.0
        _TopIntensity("_TopIntensity", Range(0.0, 1.0)) = 1.0

        [Toggle(_FLAGWAVE)]
        _FlagWaveEnable("_FlagWaveEnable", Float) = 0.0
        _FlagWaveSpeed("_FlagWaveSpeed", Range(0,10)) = 3.0
        _FlagWaveFrequencyScale("_FlagWaveFrequencyScale", Range(0,10)) = 1.0
        _FlagWaveWaveScale("_FlagWaveScale", Vector) = (0.3, 0.1, 0.3, 0.0)       
        _FlagWaveLengthOffset("_FlagWaveLengthOffset", Float) = -0.1
        _FlagWaveWindScale("_FlagWaveWindScale", Vector) = (1.0, 1.0, 1.0, 1.0)
       
        _VertexOffsetMap ("_VertexOffsetMap", 2D) = "white" {}
        _VertexOffsetMapU("_VertexOffsetMapU", Float) = 0.1
        _VertexOffsetMapV("_VertexOffsetMapV", Float) = 0.1
        _VertexOffsetIndensity("_VertexOffsetIndensity", Vector) = (1.0, 1.0, 1.0, 1.0)

        [Toggle(_STREAM_ON)]
        _EffectStreamEnable("_EffectStreamEnable", Float) = 0.0
        _StreamFactor("_StreamFactor", Range(0,100)) = 10.0
        _StreamColorFactor("_StreamColorFactor", Range(0, 1.0)) = 0.0
        _StreamTexFactor("_StreamTexFactor", Range(0, 1.0)) = 0.0
        _StreamOffsetX("_StreamOffsetX", Range(0, 5.0)) = 0.1
        _StreamOffsetY("_StreamOffsetY", Range(0, 5.0)) = 0.1
        _StreamMap("_StreamMap", 2D) = "black" {};

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _MetallicScale("Metallic Scale", Range(0, 2)) = 1
        _RoughnessScale("Roughness Scale",  Range(0, 2)) = 1

        _MetallicGlossMap("Metallic GlossMap", 2D) = "white" {}

        [ToggleOff] _SpecularHighlights("_SpecularHighlights", Float = 1.0
        [ToggleOff] _EnvironmentReflections("_EnvironmentReflections", Float = 1.0

        _NormalMap("Normal Map", 2D) = "white" {}

        _EmissionColor("Color", Color) = (0, 0, 0)
        _EmissionMap("Emission", 2D) = "white" {}
        _EmissionIntensity("Emission  Intensity", Range(0, 8)) = 1
        _CubemapEmissionCubemap("CubeMap Emission Cubemap", Cube) = "" {}

        [KeywordEnum(None, RealTime, SSR)]
        _ReflectionType("_ReflectionType", Float) = 0.0
        _ReflectionPower("_ReflectionPower", Range(0, 1)) = 0.5
        _SSRMaxSampleCount("_SSRMaxSampleCount", Range(0, 10)) = 10
        _SSRMinSampleStep("_SSRMinSampleStep", Range(2, 32)) = 12
        _SSRMaxSampleStep("_SSRMaxSampleStep", Range(32, 256)) = 64
        _SSRIntensity("_SSRIntensity", Range(0, 2)) = 1.0
        _SSRJitter("_SSRIntensity", Range(0, 1)) = 0.5
        _SSRBlurX("_SSRBlurX", Range(0, 10)) = 1
        _SSRBlurY("_SSRBlurY", Range(0, 10)) = 1

        [Toggle(_LIGHTDECAL_ON)]
        _LightDecalOn("_LightDecalOn", Float) = 0.0
        _LightDecalMap("_LightDecalMap", 2D) = "white" {}
        _LightDecalTilingOffset("_LightDecalTilingOffset", Vector) = (1, 1, 0, 0)
        _LightDecalIntensity("_LightDecalIntensity", Range(0, 8.0)) = 2.0

        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__Clip", Float) = 0.0
        [HideInInspector] _SrcBlend("__Src", Float) = 0.0
        [HideInInspector] _DstBlend("__Dst", Float) = 0.0
        [HideInInspector] _Zwrite("__Zw", Float) = 0.0
        [HideInInspector] _Cull("__cull", Float) = 0.0

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
            #pragma shader_feature_local _ _REFLECTIONTYPE_REALTIME _REFLECTIONTYPE_SSR
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
            #pragma multi_compile _ TOPCOVER _FLAGWAVE
            #pragma multi_compile _ _LIGHTDECAL_ON
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

                #if defined(_FLAGWAVE)
                    float2 vertexOffsetUV = float2(input.texcoord.x + (_VertexOffsetMapU * _Time.y), input.texcoord.y + (_VertexOffsetMapV * _Time.y))
                    half vertexOffsetTexColor = SAMPLE_TEXTURE2D_LOD(_VertexOffsetMap, sampler_VertexOffsetMap, vertexOffsetUV, 0).r;
                    vertexOffsetTexColor = _VertexOffsetIndensity * ( 2 * vertexOffsetTexColor - 1 ) * vertexOffsetTexColor;
                    AnimateFlagVertex(_FlagWaveLengthOffset, _FlagWaveSpeed, _FlagWaveFrequencyScale, _FlagWaveWaveScale.xyz, vertexOffsetTexColor, input.color.b, input.texcoord, 0.5, _FlagWaveWaveScale, input.positionOS.xyz);

                #endif

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                half3 viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

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

                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                output.positionWS = vertexInput.positionWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                
                output.fogAtten = ComputeFogAtten(vertexInput.positionWS);

                output.positionCS = vertexInput.positionCS;

                #if defined(_REFLECTIONTYPE_REALTIME) || defined(_REFLECTIONTYPE_SSR)
                    output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                #endif

                #if defined(_MYENGINE_DEBUG)
                    output.vertexColor = input.color;
                #endif

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

                #if defined(_TOPCOVER)
                    float2 topUV = input.uv * _TopMap_ST.xy * length(UNITY_MATRIX_M._m00_m10_m20) + _TopMap_ST.zw;
                    half4 topColor = SAMPLE_TEXTURE2D(_TopMap, sampler_TopMap, topUV);
                    topColor.rgb *= _TopColor.rgb;
                    half topOcclusion = topColor.a;

                    float2 topNoiseUV = input.uv * _TopBumpMap_ST.xy + _TopBumpMap_ST.zw;
                    half4 topNormalColor = SAMPLE_TEXTURE2D(_TopBumpMap, sampler_TopBumpMap, topBumpUV);
                    float3 topNormal = MyUnpackNormalRG(topNormalColor.rg);
                    half topSmoothness = saturate(1 - topNormalColor.b);

                    surfaceData.albedo = lerp(surfaceData.albedo, topColor.rgb, topMask);
                    surfaceData.occlusion = lerp(surfaceData.occlusion, topOcclusion, topMask);
                    surfaceData.normalTS = lerp(surfaceData.normalTS, topNormal, topMask);
                    surfaceData.smoothness = lerp(surfaceData.smoothness, topSmoothness, topMask);
                    surfaceData.metallic = lerp(surfaceData.metallic, 0, topMask); // 地形 金属度给0

                #endif

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

                #if defined(_MYENGINE_DEBUG)
                    return MyEngineDebug(surfaceData.metallic, surfaceData.smoothness, surfaceData.occlusion, input.vertexColor);
                #endif

                half3 reflectionParam = half3(0, 0, 0);
                #if defined(_REFLECTIONTYPE_SSR)
                    reflectionParam.z = _ReflectionPower;
                    half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
                    float2 screenUV = input.screenPos.xy / input.screenPos.w;
                    ssr = GetSSR(input.positionCS, NdotV, screenUV, inputData.positionWS, reflect(-inputData.viewDirectionWS, inputData.normalWS));
                #endif

                #if defined(_LIGHTDECAL_ON)
                    half3 lightDecalColor = SAMPLE_TEXTURE2D(_LightDecalMap, sampler_LightDecalMap, input.uv * _LightDecalTilingOffset.xy + _LightDecalTilingOffset.zw);
                    lightDecalColor *= _LightDecalIntensity;
                #else
                    half3 lightDecalColor = half3(0,0,0);
                #endif



                half4 color = UniversalComplexFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness,surfaceData.occlusion, surfaceData.emission, surfaceData.alpha,
                    reflectionParam, ssr, lightDecalColor);

                #if defined(_STREAM_ON)
                    half4 streamTexColor = SAMPLE_TEXTURE2D(_StreamMap, sampler_StreamMap, input.streamUV);
                    color = GetStreamColor(color, color.a, streamTexColor, _StreamFactor, _StreamColorFactor, _StreamTexFactor);
                #endif

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
