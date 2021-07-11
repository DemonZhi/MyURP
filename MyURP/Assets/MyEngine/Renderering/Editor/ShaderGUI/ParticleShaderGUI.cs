using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;

public class ParticleShaderGUI : ShaderGUI
{
    private static readonly int k_AddModeQueue = 3200;
    private static readonly int k_AlphaModeQueue = 3100;

    //MainTexture
    private MaterialProperty m_MainTexProp = null;
    private MaterialProperty m_MainOffsetXProp = null;
    private MaterialProperty m_MainOffsetYProp = null;

    //Vertex Offset
    private MaterialProperty m_VertexOffsetEnableProp = null;
    private MaterialProperty m_VertexOffsetTexProp = null;
    private MaterialProperty m_VertexOffsetTexUProp = null;
    private MaterialProperty m_VertexOffsetTexVProp = null;
    private MaterialProperty m_VertexOffsetIntensityProp = null;

    //Sin Wave
    private MaterialProperty m_FlagWaveSpeed = null;
    private MaterialProperty m_FlagWaveFrequencyScale = null;
    private MaterialProperty m_FlagWaveWaveScale = null;
    private MaterialProperty m_FlagWaveLengthOffset = null;
    private MaterialProperty m_FlagWaveWindScale = null;

    //Color
    private MaterialProperty m_ColorProp = null;
    private MaterialProperty m_ColorFactorProp = null;
    private MaterialProperty m_AlphaProp = null;
    private MaterialProperty m_GrayProp = null;
    private MaterialProperty m_PoserProp = null;
    private MaterialProperty m_BlackAlphaProp = null;

    //Alpha Mode
    private MaterialProperty m_AlphaClipProp = null;
    private MaterialProperty m_CutoffProp = null;
    private MaterialProperty m_SrcBlendProp = null;
    private MaterialProperty m_DstBlendProp = null;

    //Render
    private MaterialProperty m_QueueOffsetProp = null;
    private MaterialProperty m_ZWriteProp = null;
    private MaterialProperty m_ProjectionPositionOffsetProp = null;

    //Mask
    private MaterialProperty m_MaskTexProp = null;
    private MaterialProperty m_MaskOffsetXProp = null;
    private MaterialProperty m_MaskOffsetYProp = null;

    //Noise
    private MaterialProperty m_DistortionTexProp = null;
    private MaterialProperty m_DistortionOffsetXProp = null;
    private MaterialProperty m_DistortionOffsetYProp = null;

    //Noise Mask
    private MaterialProperty m_DistortionMaskTexProp = null;
    private MaterialProperty m_DistortionMaskOffsetXProp = null;
    private MaterialProperty m_DistortionMaskOffsetYProp = null;
    private MaterialProperty m_DistortionSpeedProp = null;

    //Detail
    private MaterialProperty m_DetailTexProp = null;
    private MaterialProperty m_DetailOffsetXProp = null;
    private MaterialProperty m_DetailOffsetYProp = null;

    //Fog
    private MaterialProperty m_FogEnableProp = null;
    private MaterialProperty m_FogProp = null;

    //Distortion
    private MaterialProperty m_DistortionProp = null;

    //SoftParticle
    private MaterialProperty m_SoftParticlesEnableProp = null;
    private MaterialProperty m_SoftParticlesNearFadeDistanceProp = null;
    private MaterialProperty m_SoftParticlesFarFadeDistanceProp = null;



    //RoateUV
    private MaterialProperty m_UVRotateEnableProp = null;
    private MaterialProperty m_UVRotateProp = null;
    //Radial
    private MaterialProperty m_UVRadialEnableProp = null;

    //Rim
    private MaterialProperty m_RimLightingEnableProp = null;
    private MaterialProperty m_RimLightModeProp = null;
    private MaterialProperty m_RimInnerColorProp = null;
    private MaterialProperty m_RimInnerColorFactorProp = null;
    private MaterialProperty m_RimOuterColorProp = null;
    private MaterialProperty m_RimOuterColorFactorProp = null;
    private MaterialProperty m_RimOuterThicknessProp = null;
    private MaterialProperty m_RimRadiusProp = null;
    private MaterialProperty m_RimAlphaProp = null;
    private MaterialProperty m_RimIntensityProp = null;

    //Ambient Light
    private MaterialProperty m_AmbientLightEnableProp = null;
    private MaterialProperty m_AmbientLightIntensityProp = null;

    //Dissolve
    public MaterialProperty m_DissolveModeProp = null;
    public MaterialProperty m_DissolveProp = null;
    public MaterialProperty m_DissolveSoftEnableProp = null;
    public MaterialProperty m_DissolveSoftStepProp = null;
    public MaterialProperty m_DissolveMapProp = null;
    public MaterialProperty m_DissolveOffsetXProp = null;
    public MaterialProperty m_DissolveOffsetYProp = null;
    public MaterialProperty m_DissolveMaskMapProp = null;
    public MaterialProperty m_DissolveMaskMapXSpeedProp = null;
    public MaterialProperty m_DissolveMaskMapYSpeedProp = null;

    //Dissolve Edge
    public MaterialProperty m_DissolveEdgeColorEnableProp = null;
    public MaterialProperty m_DissolveEdgeColorProp = null;
    public MaterialProperty m_DissolveEdgeFactorProp = null;
    public MaterialProperty m_DissolveEdgeWidthProp = null;
    public MaterialProperty m_DissolveEdgeWidthMidProp = null;
    public MaterialProperty m_DissolveEdgeWidthInnerProp = null;
    public MaterialProperty m_DissolveEdgeBlackProp = null;

    //Frames
    public MaterialProperty m_RowNumProp = null;
    public MaterialProperty m_ColNumProp = null;
    public MaterialProperty m_SpeedProp = null;

    //WarningArea Arrow
    public MaterialProperty m_WarningArrowFlowColorProp = null;
    public MaterialProperty m_WarningArrowDurationProp = null;
    //WarningArea Sector
    public MaterialProperty m_WarningSectorEnableProp = null;
    public MaterialProperty m_WarningSectorAngleProp = null;
    public MaterialProperty m_WarningSectorOutlineProp = null;
    public MaterialProperty m_WarningSectorOutlineAlphaProp = null;
    public MaterialProperty m_WarningSectorIndicatorAlphaProp = null;
    public MaterialProperty m_WarningSectorFlowFadeAlphaProp = null;

    private Material m_Material;
    private Material m_MaterialEditor;


    public static class Styles 
    {
        public static readonly GUIContent alphaBlendModeText =
            new GUIContent("透明混合模式","Alpha: 一般混合模式 \n Additive: 与背景叠加整体趋亮");
    }

    public enum BlendMode 
    {
        Alpha, //SrcAlpha  OneMinusSrcAlpha
        Additive //SrcAlpha One
    }

    private void Reset() 
    {
        m_GrayProp = null;

    }

    private void GetMaterialProperty(MaterialProperty[] props) 
    {

        m_MainTexProp = BaseShaderGUI.FindProperty("_MainTex",props,false);
        m_MainOffsetXProp = BaseShaderGUI.FindProperty("_MainTexOffsetX", props, false);
        m_MainOffsetYProp = BaseShaderGUI.FindProperty("_MainTexOffsetY", props, false);


        m_VertexOffsetEnableProp = BaseShaderGUI.FindProperty("_VertexOffsetEnable", props, false);
        m_VertexOffsetTexProp = BaseShaderGUI.FindProperty("_VertexOffsetTex", props, false);
        m_VertexOffsetTexUProp = BaseShaderGUI.FindProperty("_VertexOffsetTexU", props, false);
        m_VertexOffsetTexVProp = BaseShaderGUI.FindProperty("_VertexOffsetTexV", props, false);
        m_VertexOffsetIntensityProp = BaseShaderGUI.FindProperty("_VertexOffsetIndensity", props, false);


        m_FlagWaveSpeed = BaseShaderGUI.FindProperty("_FlagWaveSpeed", props, false);
        m_FlagWaveFrequencyScale = BaseShaderGUI.FindProperty("_FlagWaveFrequencyScale", props, false);
        m_FlagWaveWaveScale = BaseShaderGUI.FindProperty("_FlagWaveScale", props, false);
        m_FlagWaveLengthOffset = BaseShaderGUI.FindProperty("_FlagWaveLengthOffset", props, false);
        m_FlagWaveWindScale = BaseShaderGUI.FindProperty("_FlagWaveWindScale", props, false);


        m_ColorProp = BaseShaderGUI.FindProperty("_Color", props, false);
        m_ColorFactorProp = BaseShaderGUI.FindProperty("_ColorFactor", props, false);
        m_PoserProp = BaseShaderGUI.FindProperty("_Poser", props, false);
        m_GrayProp = BaseShaderGUI.FindProperty("_Gray", props, false);
        m_BlackAlphaProp = BaseShaderGUI.FindProperty("_BlackAlpha", props, false);
        m_AlphaProp = BaseShaderGUI.FindProperty("_Alpha", props, false);

        m_AlphaClipProp = BaseShaderGUI.FindProperty("_AlphaClip", props, false);
        m_CutoffProp = BaseShaderGUI.FindProperty("_Cutoff", props, false);

        m_SrcBlendProp = BaseShaderGUI.FindProperty("_SrcBlend", props, false);
        m_DstBlendProp = BaseShaderGUI.FindProperty("_DstBlend", props, false);


        m_QueueOffsetProp = BaseShaderGUI.FindProperty("_QueueOffset", props, false);
        m_ZWriteProp = BaseShaderGUI.FindProperty("_ZWrite", props, false);
        m_ProjectionPositionOffsetProp = BaseShaderGUI.FindProperty("_ProjectionPositionOffsetZ", props, false);



        m_MaskTexProp = BaseShaderGUI.FindProperty("_MaskTex", props, false);
        m_MaskOffsetXProp = BaseShaderGUI.FindProperty("_MaskOffsetX", props, false);
        m_MaskOffsetYProp = BaseShaderGUI.FindProperty("_MaskOffsetY", props, false);


        m_DistortionTexProp = BaseShaderGUI.FindProperty("_DistortionMap", props, false);
        m_DistortionOffsetXProp = BaseShaderGUI.FindProperty("_DistortionOffsetX", props, false);
        m_DistortionOffsetYProp = BaseShaderGUI.FindProperty("_DistortionOffsetY", props, false);


        m_DistortionMaskTexProp = BaseShaderGUI.FindProperty("_DistortionMaskMap", props, false);
        m_DistortionMaskOffsetXProp = BaseShaderGUI.FindProperty("_DistortionMaskU", props, false);
        m_DistortionMaskOffsetYProp = BaseShaderGUI.FindProperty("_DistortionMaskV", props, false);
        m_DistortionSpeedProp = BaseShaderGUI.FindProperty("_DistortionSpeed", props, false);


        m_DetailTexProp = BaseShaderGUI.FindProperty("_DetailTex", props, false);
        m_DetailOffsetXProp = BaseShaderGUI.FindProperty("_DetailOffsetX", props, false);
        m_DetailOffsetYProp = BaseShaderGUI.FindProperty("_DetailOffsetY", props, false);


        m_FogEnableProp = BaseShaderGUI.FindProperty("_FogEnable", props, false);
        m_FogProp = BaseShaderGUI.FindProperty("_Fog", props, false);


        m_DistortionProp = BaseShaderGUI.FindProperty("_DistortionIntensity", props, false);


        m_SoftParticlesEnableProp = BaseShaderGUI.FindProperty("_SoftParticlesEnable", props, false);
        m_SoftParticlesNearFadeDistanceProp = BaseShaderGUI.FindProperty("_SoftParticlesNearFadeDistance", props, false);
        m_SoftParticlesFarFadeDistanceProp = BaseShaderGUI.FindProperty("_SoftParticlesFarFadeDistance", props, false);

        m_UVRotateEnableProp = BaseShaderGUI.FindProperty("_UVRotateEnabled", props, false);
        m_UVRotateProp = BaseShaderGUI.FindProperty("_UVRotate", props, false);

        m_UVRadialEnableProp = BaseShaderGUI.FindProperty("_UVRadialEnabled", props, false);


        m_RimLightingEnableProp = null;
        m_RimLightModeProp = null;
        m_RimInnerColorProp = null;
        m_RimInnerColorFactorProp = null;
        m_RimOuterColorProp = null;
        m_RimOuterColorFactorProp = null;
        m_RimOuterThicknessProp = null;
        m_RimRadiusProp = null;
        m_RimAlphaProp = null;
        m_RimIntensityProp = null;


        m_AmbientLightEnableProp = null;
        m_AmbientLightIntensityProp = null;

        //Dissolve
        m_DissolveModeProp = null;
        m_DissolveProp = null;
        m_DissolveSoftEnableProp = null;
        m_DissolveSoftStepProp = null;
        m_DissolveMapProp = null;
        m_DissolveOffsetXProp = null;
        m_DissolveOffsetYProp = null;
        m_DissolveMaskMapProp = null;
        m_DissolveMaskMapXSpeedProp = null;
        m_DissolveMaskMapYSpeedProp = null;
        
        
        m_DissolveEdgeColorEnableProp = null;
        m_DissolveEdgeColorProp = null;
        m_DissolveEdgeFactorProp = null;
        m_DissolveEdgeWidthProp = null;
        m_DissolveEdgeWidthMidProp = null;
        m_DissolveEdgeWidthInnerProp = null;
        m_DissolveEdgeBlackProp = null;
        
        
        m_RowNumProp = null;
        m_ColNumProp = null;
        m_SpeedProp = null;
        
        
        m_WarningArrowFlowColorProp = null;
        m_WarningArrowDurationProp = null;
        
        m_WarningSectorEnableProp = null;
        m_WarningSectorAngleProp = null;
        m_WarningSectorOutlineProp = null;
        m_WarningSectorOutlineAlphaProp = null;
        m_WarningSectorIndicatorAlphaProp = null;
        m_WarningSectorFlowFadeAlphaProp = null;

























































































}
}
