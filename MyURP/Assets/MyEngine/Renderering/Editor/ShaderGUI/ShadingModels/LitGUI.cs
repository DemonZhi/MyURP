using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace MyEngine.EditorExtensition.ShaderGUI 
{
    public static class LitGUI 
    {
        public enum WorkflowMode
        {
            Specular = 0,
            Metallic
        }

        public enum SmoothnessMapChannel
        {
            SpecularMetallicAlpha,
            AlbedoAlpha,
        }

        public enum DepthOnlyMode
        {
            Disabled = 0 ,
            Enable = 1,
        }

        public static class Styles
        {
            public static GUIContent workflowModeText = new GUIContent("Workflow Mode",
                "Select a workflow that fits your textures. Choose between Metallic or Specular.");

            public static GUIContent specularMapText =
                new GUIContent("Specular Map", "Sets and configures the map and color for the Specular workflow.");

            public static GUIContent metallicMapText =
                new GUIContent("Metallic Map »ìºÏÌùÍ¼", "R£º´Ö²Ú¶È G ½ðÊô¶È B AOÕÚÕÖ.");



            public static GUIContent smoothnessText = new GUIContent("Smoothness",
                "Controls the spread of highlights and reflections on the surface.");

            public static GUIContent smoothnessMapChannelText =
                new GUIContent("Source",
                    "Specifies where to sample a smoothness map from. By default, uses the alpha channel for your map.");

            public static GUIContent highlightsText = new GUIContent("Specular Highlights",
                "When enabled, the Material reflects the shine from direct lighting.");

            public static GUIContent reflectionsText =
                new GUIContent("Environment Reflections",
                    "When enabled, the Material samples reflections from the nearest Reflection Probes or Lighting Probe.");

            public static GUIContent heightMapText = new GUIContent("Height Map",
                "Specifies the Height Map (G) for this Material.");

            public static GUIContent occlusionText = new GUIContent("Occlusion Map",
                "Sets an occlusion map to simulate shadowing from ambient lighting.");

            public static readonly string[] metallicSmoothnessChannelNames = { "Metallic Alpha", "Albedo Alpha" };
            public static readonly string[] specularSmoothnessChannelNames = { "Specular Alpha", "Albedo Alpha" };

            public static GUIContent clearCoatText = new GUIContent("Clear Coat",
                "A multi-layer material feature which simulates a thin layer of coating on top of the surface material." +
                "\nPerformance cost is considerable as the specular component is evaluated twice, once per layer.");

            public static GUIContent clearCoatMaskText = new GUIContent("Mask",
                "Specifies the amount of the coat blending." +
                "\nActs as a multiplier of the clear coat map mask value or as a direct mask value if no map is specified." +
                "\nThe map specifies clear coat mask in the red channel and clear coat smoothness in the green channel.");

            public static GUIContent clearCoatSmoothnessText = new GUIContent("Smoothness",
                "Specifies the smoothness of the coating." +
                "\nActs as a multiplier of the clear coat map smoothness value or as a direct smoothness value if no map is specified.");
        }
        public struct LitProperties
        {

            // Surface Input Props
            public MaterialProperty metallicScale;
            public MaterialProperty specColor;
            public MaterialProperty metallicGlossMap;
            public MaterialProperty roughnessScale;
            public MaterialProperty bumpMapProp;

            public MaterialProperty emissionIntensity;
            public MaterialProperty cubemapEmissionCubemap;

            //planarReflection
            public MaterialProperty reflectionType;
            public MaterialProperty reflectionPower;

            //SSR
            public MaterialProperty ssrMaxSampleCount;
            public MaterialProperty ssrMinSampleStep;
            public MaterialProperty ssrMaxSampleStep;
            public MaterialProperty ssrIntensity;
            public MaterialProperty ssrJitter;
            public MaterialProperty ssrBlurX;
            public MaterialProperty ssrBlurY;

            //Top
            public MaterialProperty topEnable;
            public MaterialProperty topMap;
            public MaterialProperty topColor;
            public MaterialProperty topNoiseMap;
            public MaterialProperty topBump;
            public MaterialProperty topOffset;
            public MaterialProperty topAOOffset;
            public MaterialProperty topContrast;
            public MaterialProperty topIntensity;

            //FlagWave
            public MaterialProperty flagWaveEnable;
            public MaterialProperty flagWaveSpeed;
            public MaterialProperty flagWaveFrequencyScale;
            public MaterialProperty flagWaveWaveScale;

            public MaterialProperty flagWaveLengthOffset;
            public MaterialProperty flagWaveWindScale;

            public MaterialProperty vertexOffsetMapProp;
            public MaterialProperty vertexOffsetMapUProp;
            public MaterialProperty vertexOffsetMapVProp;
            public MaterialProperty vertexOffsetIntensityProp;

            //Stream
            public MaterialProperty effectStreamEnableProp;
            public MaterialProperty effectStreamFactorProp;
            public MaterialProperty effectStreamColorFactorProp;
            public MaterialProperty effectStreamTexFactorProp;
            public MaterialProperty effectStreamOffsetXProp;
            public MaterialProperty effectStreamOffsetYProp;            
            public MaterialProperty effectStreamMapProp;

            //Blur
            public MaterialProperty blurOffsetXProp;
            public MaterialProperty blurOffsetYProp;
            public MaterialProperty transmittanceProp;

            //Light Decal
            public MaterialProperty lightDecalOnProp;
            public MaterialProperty lightDecalMapProp;
            public MaterialProperty lightDecalTilingOffsetProp;
            public MaterialProperty lightDecalIntensityProp;


            /* 
                        public LitProperties(MaterialProperty[] properties)
                        {
                            // Surface Input Props
                            metallicScale = BaseShaderGUI.FindProperty("_MetallicScale", properties, false);
                            specColor = BaseShaderGUI.FindProperty("_SpecColor", properties, false);
                            metallicGlossMap = BaseShaderGUI.FindProperty("_MetallicGlossMap", properties, false);
                            roughnessScale = BaseShaderGUI.FindProperty("_RoughnessScale", properties, false);
                            bumpMapProp = BaseShaderGUI.FindProperty("_NormalMap", properties, false);
                            emissionIntensity = BaseShaderGUI.FindProperty("_EmissionIntensity", properties, false); 
                            cubemapEmissionCubemap = BaseShaderGUI.FindProperty("_CubemapEmissionCubemap", properties, false); 

                            // Planar Reflection
                            reflectionType = BaseShaderGUI.FindProperty("_ReflectionType", properties, false); 
                            reflectionPower = BaseShaderGUI.FindProperty("_ReflectionPower", properties, false);


                            ssrMaxSampleCount = BaseShaderGUI.FindProperty("_SSRMaxSampleCount", properties, false); 
                            ssrMinSampleStep = BaseShaderGUI.FindProperty("_SSRMinSampleStep", properties, false); 
                            ssrMaxSampleStep = BaseShaderGUI.FindProperty("_SSRMaxSampleStep", properties, false);
                            ssrIntensity = BaseShaderGUI.FindProperty("_SSRIntensity", properties, false); 
                            ssrJitter = BaseShaderGUI.FindProperty("_SSRJitter", properties, false); 
                            ssrBlurX = BaseShaderGUI.FindProperty("_SSRBlurX", properties, false); 
                            ssrBlurY = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false); 


                            topEnable = BaseShaderGUI.FindProperty("topEnable", properties, false);
                            topMap = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topColor = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topNoiseMap = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topBump = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topOffset = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topAOOffset = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topContrast = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);
                            topIntensity = BaseShaderGUI.FindProperty("_SSRBlurY", properties, false);

                           flagWaveEnable;
                            flagWaveSpeed;
                            flagWaveFrequencyScale;
                            flagWaveWaveScale;

                            flagWaveLengthOffset;
                            flagWaveWindScale;

                            vertexOffsetMapProp;
                            vertexOffsetMapUProp;
                            vertexOffsetMapVProp;
                            vertexOffsetIntensityProp;


                            effectStreamEnableProp;
                            effectStreamFactorProp;
                            effectStreamColorFactorProp
                            effectStreamTexFactorProp;
                            effectStreamOffsetXProp;
                            effectStreamOffsetYProp;
                            effectStreamMapProp;


                            blurOffsetXProp;
                            blurOffsetYProp;
                            transmittanceProp;


                            lightDecalOnProp;
                            lightDecalMapProp;
                            lightDecalTilingOffsetProp;
                            lightDecalIntensityProp;*/

        }
    }
    }


