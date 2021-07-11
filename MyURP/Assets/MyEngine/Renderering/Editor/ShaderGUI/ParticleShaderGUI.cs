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

    //Alpha Clip
    private MaterialProperty m_AlphaClipProp = null;
    private MaterialProperty m_CutoffProp = null;

    //Alpha Mode
    private MaterialProperty m_AlphaModeProp = null;
    private MaterialProperty m_SrcBlendProp = null;
    private MaterialProperty m_DstBlendProp = null;

    //Cull
    private MaterialProperty m_CullProp = null;

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
    public MaterialProperty m_DissolveTypeProp = null;
    public MaterialProperty m_DissolveProp = null;
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
    public MaterialProperty m_WarningSectorIndicatorProp = null;
    public MaterialProperty m_WarningSectorFlowFadeProp = null;

    private Material m_Material;
    private MaterialEditor m_MaterialEditor;


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

        m_AlphaModeProp = BaseShaderGUI.FindProperty("_AlphaMode", props, false);        
        m_SrcBlendProp = BaseShaderGUI.FindProperty("_SrcBlend", props, false);
        m_DstBlendProp = BaseShaderGUI.FindProperty("_DstBlend", props, false);

        m_CullProp = BaseShaderGUI.FindProperty("_Cull", props, false);

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


        m_RimLightingEnableProp = BaseShaderGUI.FindProperty("_RimLightingEnable", props, false);
        m_RimLightModeProp = BaseShaderGUI.FindProperty("_RimLightMode", props, false);
        m_RimOuterColorProp = BaseShaderGUI.FindProperty("_RimOuterColor", props, false);
        m_RimOuterColorFactorProp = BaseShaderGUI.FindProperty("_RimOuterColorFactor", props, false);
        m_RimInnerColorProp = BaseShaderGUI.FindProperty("_RimInnerColor", props, false);
        m_RimInnerColorFactorProp = BaseShaderGUI.FindProperty("_RimInnerColorFactor", props, false);
        m_RimOuterThicknessProp = BaseShaderGUI.FindProperty("_RimOuterTickness", props, false);
        m_RimRadiusProp = BaseShaderGUI.FindProperty("_RimRadius", props, false);
        m_RimAlphaProp = BaseShaderGUI.FindProperty("_RimAlpha", props, false);
        m_RimIntensityProp = BaseShaderGUI.FindProperty("_RimIntensity", props, false);


        m_AmbientLightEnableProp = BaseShaderGUI.FindProperty("_AmbientingEnable", props, false);
        m_AmbientLightIntensityProp = BaseShaderGUI.FindProperty("_AmbientingIntensity", props, false);

        //Dissolve
        m_DissolveTypeProp = BaseShaderGUI.FindProperty("_DissolveType", props, false);
        m_DissolveProp = BaseShaderGUI.FindProperty("_Dissolve", props, false);
     
        
        m_DissolveMapProp = BaseShaderGUI.FindProperty("_DissolveMap", props, false);
        m_DissolveOffsetXProp = BaseShaderGUI.FindProperty("_DissolveOffsetX", props, false);
        m_DissolveOffsetYProp = BaseShaderGUI.FindProperty("_DissolveOffsetY", props, false);

        m_DissolveMaskMapProp = BaseShaderGUI.FindProperty("_DissolveMaskMap", props, false);
        m_DissolveMaskMapXSpeedProp = BaseShaderGUI.FindProperty("_DissolveMaskMapUSpeed", props, false);
        m_DissolveMaskMapYSpeedProp = BaseShaderGUI.FindProperty("_DissolveMaskMapVSpeed", props, false);
        
        
        m_DissolveEdgeColorEnableProp = BaseShaderGUI.FindProperty("_DissolveEdgeColorEnable", props, false);
        m_DissolveEdgeColorProp = BaseShaderGUI.FindProperty("_EdgeColor", props, false);
        m_DissolveEdgeFactorProp = BaseShaderGUI.FindProperty("_EdgeColorFactor", props, false);
        m_DissolveEdgeWidthProp = BaseShaderGUI.FindProperty("_EdgeWidth", props, false);
        m_DissolveEdgeWidthMidProp = BaseShaderGUI.FindProperty("_EdgeWidthMid", props, false);
        m_DissolveEdgeWidthInnerProp = BaseShaderGUI.FindProperty("_EdgeWidthInner", props, false);
        m_DissolveEdgeBlackProp = BaseShaderGUI.FindProperty("_EdgeBlack", props, false);
        
        
        m_RowNumProp = BaseShaderGUI.FindProperty("_RowNum", props, false);
        m_ColNumProp = BaseShaderGUI.FindProperty("_ColNum", props, false);
        m_SpeedProp = BaseShaderGUI.FindProperty("_Speed", props, false);
        
        
        m_WarningArrowFlowColorProp = BaseShaderGUI.FindProperty("_FlowColor", props, false);
        m_WarningArrowDurationProp = BaseShaderGUI.FindProperty("_Duration", props, false);
        
        m_WarningSectorEnableProp = BaseShaderGUI.FindProperty("_WarningSector", props, false);
        m_WarningSectorAngleProp = BaseShaderGUI.FindProperty("_WarningAngle", props, false);
        m_WarningSectorOutlineProp = BaseShaderGUI.FindProperty("_WarningOutline", props, false);
        m_WarningSectorOutlineAlphaProp = BaseShaderGUI.FindProperty("_WarningOutlineAlpha", props, false);
        m_WarningSectorIndicatorProp = BaseShaderGUI.FindProperty("_WarningIndicator", props, false);
        m_WarningSectorFlowFadeProp = BaseShaderGUI.FindProperty("_FlowFade", props, false);
    }

    private void ShaderPropertiesGUI() 
    {
        m_MaterialEditor.SetDefaultGUIWidths();
        EditorGUIUtility.labelWidth = 150f;
        DrawMain();
    }

    private void DrawMain() 
    {
        m_MaterialEditor.ShaderProperty(m_MainTexProp, "主帖图");
        if (m_MainOffsetXProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_MainOffsetXProp, "主帖图 U流动");
            m_MaterialEditor.ShaderProperty(m_MainOffsetYProp, "主帖图 V流动");
        }
        GUILayout.Space(5);

        if (m_ColorProp != null ) 
        {
            m_MaterialEditor.ShaderProperty(m_ColorProp, "主颜色");
            m_MaterialEditor.ShaderProperty(m_ColorFactorProp, "主颜色 强度");
            if (m_PoserProp != null) 
            {
                m_MaterialEditor.ShaderProperty(m_PoserProp, "对比度");
            }
            if (m_GrayProp != null)
            {
                m_MaterialEditor.ShaderProperty(m_GrayProp, "灰度");
            }
            if (m_BlackAlphaProp != null)
            {
                m_MaterialEditor.ShaderProperty(m_BlackAlphaProp, "去黑底");
            }
            if (m_FogEnableProp != null)
            {
                m_MaterialEditor.ShaderProperty(m_FogEnableProp, "雾效");
                if (m_FogEnableProp.floatValue == 1) 
                {
                    m_MaterialEditor.ShaderProperty(m_FogProp, "雾效强度");
                }
            }
        }
    }

    private void DrawVertexOffset()
    {
       
        if (m_VertexOffsetEnableProp != null)
        {
            m_MaterialEditor.ShaderProperty(m_VertexOffsetEnableProp, "顶点偏移");
            if (m_VertexOffsetEnableProp.floatValue == 1)
            {
                m_MaterialEditor.ShaderProperty(m_VertexOffsetTexProp, "顶点偏移图");
                m_MaterialEditor.ShaderProperty(m_VertexOffsetTexUProp, "顶点偏移图 U流动");
                m_MaterialEditor.ShaderProperty(m_VertexOffsetTexVProp, "顶点偏移图 V流动");
                m_MaterialEditor.ShaderProperty(m_VertexOffsetIntensityProp, "顶点偏移强度");
            }
        }

        if (m_FlagWaveSpeed != null)
        {
            m_MaterialEditor.ShaderProperty(m_FlagWaveSpeed, "飘动速度");
            m_MaterialEditor.ShaderProperty(m_FlagWaveFrequencyScale, "飘动频率");
            m_MaterialEditor.ShaderProperty(m_FlagWaveWaveScale, "飘动幅度");
            m_MaterialEditor.ShaderProperty(m_FlagWaveLengthOffset, "整体缩短");
            m_MaterialEditor.ShaderProperty(m_FlagWaveWindScale, "总体缩放");

            m_MaterialEditor.ShaderProperty(m_VertexOffsetTexProp, "顶点偏移图");
            m_MaterialEditor.ShaderProperty(m_VertexOffsetTexUProp, "顶点偏移图 U流动");
            m_MaterialEditor.ShaderProperty(m_VertexOffsetTexVProp, "顶点偏移图 V流动");
            m_MaterialEditor.ShaderProperty(m_VertexOffsetIntensityProp, "顶点偏移强度");
        }        
    }

    private void DrawAlpha() 
    {
        if (m_AlphaProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_AlphaProp, "Alpha");
        }

        if (m_AlphaClipProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_AlphaClipProp, "Alpha Clip 透明裁剪 ");
            if (m_AlphaClipProp.floatValue == 1) 
            {
                m_Material.EnableKeyword("_ALPHATEST_ON");
                m_Material.SetOverrideTag("RenderType","TransparentCutout");
                m_ZWriteProp.floatValue = 1;
                m_MaterialEditor.ShaderProperty(m_CutoffProp, "Cutoff 裁剪偏移 ");
            }
            else
            {
                m_Material.DisableKeyword("_ALPHATEST_ON");
                m_Material.SetOverrideTag("RenderType", "Transparent");
                m_ZWriteProp.floatValue = 0;
            }
        }

        if (m_AlphaModeProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_AlphaModeProp, "透明混合模式");
            SetBlendMode(m_Material, (BlendMode)m_AlphaModeProp.floatValue);
        }
    }

    private void DrawMask() 
    {

        if (m_MaskTexProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_MaskTexProp, "遮罩图");
            if (m_MaskOffsetXProp != null) 
            {
                m_MaterialEditor.ShaderProperty(m_MaskOffsetXProp, "遮罩图U 流动速度");
                m_MaterialEditor.ShaderProperty(m_MaskOffsetYProp, "透明混V 流动速度");
            }
        }

    }

    private void DrawDecal() 
    {
        m_Material.SetInt("_StencilComp", true ? (int)CompareFunction.NotEqual : (int)CompareFunction.Always);
    }

    private void DrawRotateRadial() 
    {
        CoreUtils.SetKeyword(m_Material,"_UV_ROTATE_ON", true);
        CoreUtils.SetKeyword(m_Material,"_UV_RADIAL_ON", true);
    }

    private void DrawCullMode() 
    {
        if (m_CullProp != null) 
        {
            m_MaterialEditor.ShaderProperty(m_CullProp, "剔除模式");
        }
    }

    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader) 
    {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);

        if (material != null) 
        {
            Reset();

            material.SetFloat("_Cull", (float)CullMode.Back);
            material.SetFloat("_AlphaMode", (float)BlendMode.Additive);
            material.SetFloat("_ZWrite", 0);
            SetBlendMode(material, BlendMode.Additive);         
        }
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        m_MaterialEditor = materialEditor;
        m_Material = materialEditor.target as Material;
        GetMaterialProperty(properties);
        ShaderPropertiesGUI();
    }

    private void SetBlendMode(Material material, BlendMode mode) 
    {
        switch (mode)
        {
            case BlendMode.Alpha:
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.renderQueue = 3100;
                break;
            case BlendMode.Additive:
                material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One);
                material.renderQueue = 3200;
                break;
            default:
                break;
        }
    }
}
