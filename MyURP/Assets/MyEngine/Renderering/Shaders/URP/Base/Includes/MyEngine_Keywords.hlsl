#ifndef MYENGINE_KEYWORDS_INCLUDE
#define MYENGINE_KEYWORDS_INCLUDE

#if defined(_MYENGINE_QUALITY_HIGH)
    
    //Common Begin
    #define _SHADOWS_SOFT
    #define _MICRO_SHADOW
    #define _ENV_REFLECTION
    #define _USE_NORMALMAP
    #define _SCENE_WET
    #define _ADDITIONAL_LIGHTS

    //Role
    #define _ROLE_CRSTALON
    #define _ROLE_HIGH_BRDF
    #define _ROLE_DIFFUSENORMAL

    //Water
    #define _WATER_REFRACTION
    #define _WATER_BUMP_MAP
    #define _WATER_SECOND_BUMP_MAP
    #define _WATER_SPECULARHIGHLIGHTS_ON
    #define _WATER_ALPHAFADE

    //Terrain
    #define _USE_WETMAP

    //Foliage
    #define _TRANSLUCENCY_LIT
    #define _FOLIAGE_ANIMATE
#else

    #define _ADDITIONAL_LIGHTS
    #define _WET_BUMP_MAP
    #undef  _REFLECTIONTYPE_REALTIME


#endif

#endif