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
    private MaterialProperty m_DistortionStrengthProp = null;

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

    //Decal
    private MaterialProperty m_DecalEnableProp = null;

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


        m_VertexOffsetEnableProp = BaseShaderGUI.FindProperty("_MainTex", props, false);
        m_VertexOffsetTexProp = BaseShaderGUI.FindProperty("_MainTex", props, false);
        m_VertexOffsetTexUProp = BaseShaderGUI.FindProperty("_MainTex", props, false);
        m_VertexOffsetTexVProp = BaseShaderGUI.FindProperty("_MainTex", props, false);
        m_VertexOffsetIntensityProp = BaseShaderGUI.FindProperty("_MainTex", props, false);


        m_FlagWaveSpeed = null;
        m_FlagWaveFrequencyScale = null;
        m_FlagWaveWaveScale = null;
        m_FlagWaveLengthOffset = null;
        m_FlagWaveWindScale = null;


        m_ColorProp = null;
        m_ColorFactorProp = null;
        m_AlphaProp = null;
        m_GrayProp = null;
        m_PoserProp = null;
        m_BlackAlphaProp = null;


        m_AlphaClipProp = null;
        m_CutoffProp = null;
        m_SrcBlendProp = null;
        m_DstBlendProp = null;


        m_QueueOffsetProp = null;
        m_ZWriteProp = null;
        m_ProjectionPositionOffsetProp = null;



        m_MaskTexProp = null;
        m_MaskOffsetXProp = null;
        m_MaskOffsetYProp = null;


        m_DistortionTexProp = null;
        m_DistortionOffsetXProp = null;
        m_DistortionOffsetYProp = null;
        m_DistortionStrengthProp = null;


        m_DistortionMaskTexProp = null;
        m_DistortionMaskOffsetXProp = null;
        m_DistortionMaskOffsetYProp = null;
        m_DistortionSpeedProp = null;


        m_DetailTexProp = null;
        m_DetailOffsetXProp = null;
        m_DetailOffsetYProp = null;


        m_FogEnableProp = null;
        m_FogProp = null;


        m_DistortionProp = null;


        m_SoftParticlesEnableProp = null;
        m_SoftParticlesNearFadeDistanceProp = null;
        m_SoftParticlesFarFadeDistanceProp = null;


        m_DecalEnableProp = null;


        m_UVRotateEnableProp = null;
        m_UVRotateProp = null;

        m_UVRadialEnableProp = null;


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



























































































    }
}
