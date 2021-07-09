#ifndef MYENGINE_URP_COMMON_BASE
#define MYENGINE_URP_COMMON_BASE

    half _GlobalBrightness;

    real3 SafeNormalize_Half3(real3 inVec)
    {
        real dp3 = max(REAL_MIN, dot(inVec, inVec));
        return inVec * rsqrt(dp3);
    }

    real2 SafeNormalize_Half2(real2 inVec)
    {
        real dp2 = max(REAL_MIN, dot(inVec, inVec));
        return inVec * rsqrt(dp2);
    }

    real3 MyUnpackNormal(real4 packedNormal)
    {
        return packedNormal.rgb * 2.0 - 1.0;
    }

    real3 MyUnpackNormalScale(real4 packedNormal, real scale = 1.0)
    {
        real3 normal;
        normal.xyz = packedNormal.rgb * 2.0 - 1.0; 
        normal.xy *= scale;
        return normal;
    }

    real3 MyUnpackNormalRG(real2 packedNormal)
    {
        real3 normal;
        normal.xy = packedNormal.rg * 2.0 - 1.0;
        normal.z = max(1.0e-16 , sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));
        return normal; 
    }

    real3 ApplyBrightness(real3 color)
    {
        return color * _GlobalBrightness;
    }

    real linstep(real min, real max, real v)
    {
        return saturate( (v- min ) / (max - min) );
    }

    real ApplyMicroShadow(real ao, real3 N , real3 L, real shadow)
    {
#if defined(_MICRO_SHADOW)
        real aperture = 2.0 * ao * ao ;
        real microShadow = saturate( abs( dot(N,L) ) + aperture - 1.0  );
        return shadow * microShadow;
#else
        return shadow;
#endif

    }

#endif