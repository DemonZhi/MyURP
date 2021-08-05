#ifndef MYENGINE_URP_DEBUG_INCLUDE
#define MYENGINE_URP_DEBUG_INCLUDE

#if defined(_MYENGINE_DEBUG)
    half4 MyEngineDebug(half metallic, half smoothness, half occlusion, half4 vertexColor)
    {
        #if defined(_MYENGINE_DEBUG_METALLIC)
            return half4(metallic.xxx, 1);
        #endif

        #if defined(_MYENGINE_DEBUG_ROUGHNESS)
            half roughness = saturate( 1 - smoothness);
            return half4(roughness.xxx, 1);
        #endif
        
        #if defined(_MYENGINE_DEBUG_OCCLUSION)            
            return half4(occlusion.xxx, 1);
        #endif

        #if defined(_MYENGINE_DEBUG_VERTEX_COLOR)
            return vertexColor;
        #endif

        #if defined(_MYENGINE_DEBUG_VERTEX_COLOR_R)
            return half4( vertexColor.rrr, 1);
        #endif

        #if defined(_MYENGINE_DEBUG_VERTEX_COLOR_G)
            return half4( vertexColor.ggg, 1);
        #endif

        #if defined(_MYENGINE_DEBUG_VERTEX_COLOR_B)
            return half4( vertexColor.bbb, 1);
        #endif

        #if defined(_MYENGINE_DEBUG_VERTEX_COLOR_A)
            return half4( vertexColor.aaa, 1);
        #endif

        return half4(0,0,0,1);
    }
#endif

#endif