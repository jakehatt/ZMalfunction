#ifndef __OUTLINE_CORE__
#define __OUTLINE_CORE__

  ////Outline
        /////
		#ifndef MAX2
        #define MAX2(v) max(v.x, v.y)
        #endif
        #ifndef MIN2
        #define MIN2(v) min(v.x, v.y)
        #endif
        #ifndef MAX3
        #define MAX3(v) max(v.x, max(v.y, v.z))
        #endif
        #ifndef MIN3
        #define MIN3(v) min(v.x, min(v.y, v.z))
        #endif
        #ifndef MAX4
        #define MAX4(v) max(v.x, max(v.y, max(v.z, v.w)))
        #endif
        #ifndef MIN4
        #define MIN4(v) min(v.x, min(v.y, min(v.z, v.w)))
        #endif

        float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
        {
            return (value - inputMin) * ((outputMax - outputMin) / (inputMax - inputMin)) + outputMin;
        }

        float3 GetNormal(float2 uv)
        {
            float3 normal;
            normal = SampleSceneNormals(uv);
            float3 worldNormal = mul((float3x3)unity_MatrixInvV, normal);
            return worldNormal;
        }

        float DirectionalSampleNormal(float2 uv, float3 offset)
        {
            float3 n_c = GetNormal(uv);
            float3 n_l = GetNormal(uv - offset.xz);
            float3 n_r = GetNormal(uv + offset.xz);
            float3 n_u = GetNormal(uv + offset.zy);
            float3 n_d = GetNormal(uv - offset.zy);

            float sobelNormalDot =  dot(n_l, n_c) + 
                                    dot(n_r, n_c) +
                                    dot(n_u, n_c) +
                                    dot(n_d, n_c);
            sobelNormalDot = remap(sobelNormalDot, -4, 4, 0, 1);
            sobelNormalDot = 1 - sobelNormalDot;

            return sobelNormalDot;
        }

        float3 SobelSampleNormal(float2 uv, float3 offset)
        {        
            float3 n_c = GetNormal(uv);
            float3 n_l = GetNormal(uv - offset.xz);
            float3 n_r = GetNormal(uv + offset.xz);
            float3 n_u = GetNormal(uv + offset.zy);
            float3 n_d = GetNormal( uv - offset.zy);

            return (n_c - n_l) +
                   (n_c - n_r) +
                   (n_c - n_u) +
                   (n_c - n_d);
        }            

        //////////////////////////////////////////////////////////////////////////////////////
        //This MeshEdges function is from repository of Alexander Federwisch
        //https://github.com/Daodan317081/reshade-shaders
        ///BSD 3-Clause License
        // Copyright (c) 2018-2019, Alexander Federwisch
        // All rights reserved.
         float MeshEdges(float depthC, float4 depth1, float4 depth2) 
         {
            /******************************************************************************
                Outlines type 2:
                This method calculates how flat the plane around the center pixel is.
                Can be used to draw the polygon edges of a mesh and its outline.
            ******************************************************************************/
            float depthCenter = depthC;
            float4 depthCardinal = float4(depth1.x, depth2.x, depth1.z, depth2.z);
            float4 depthInterCardinal = float4(depth1.y, depth2.y, depth1.w, depth2.w);
            //Calculate the min and max depths
            float2 mind = float2(MIN4(depthCardinal), MIN4(depthInterCardinal));
            float2 maxd = float2(MAX4(depthCardinal), MAX4(depthInterCardinal));
            float span = MAX2(maxd) - MIN2(mind) + 0.00001;

            //Normalize values
            depthCenter /= span;
            depthCardinal /= span;
            depthInterCardinal /= span;
            //Calculate the (depth-wise) distance of the surrounding pixels to the center
            float4 diffsCardinal = abs(depthCardinal - depthCenter);
            float4 diffsInterCardinal = abs(depthInterCardinal - depthCenter);
            //Calculate the difference of the (opposing) distances
            float2 meshEdge = float2(
                max(abs(diffsCardinal.x - diffsCardinal.y), abs(diffsCardinal.z - diffsCardinal.w)),
                max(abs(diffsInterCardinal.x - diffsInterCardinal.y), abs(diffsInterCardinal.z - diffsInterCardinal.w))
            );

            return MAX2(meshEdge);
        }
        /////////////////////////////////////////////////////////////////////////////////////



#if UNITY_VERSION >= 202310
        float GetClosenessBoostEyeDepth(float3 viewDirWS, float eyeDepth)
        {
            float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
            float cameraDistance = - eyeDepth / dot(viewDirWS, cameraForward);
            float dis = cameraDistance * 0.01;
            float disBoost = smoothstep(_BoostFar, _BoostNear, dis) * _ClosenessBoostThickness + 1;
            return disBoost;
        }

        float GetDistanceFadeEyeDepth(float3 viewDirWS, float eyeDepth)
        {
            // float linearDepth = (1.0 / depth01 - _ZBufferParams.y) / _ZBufferParams.x;
            // float eyeDepth = LinearEyeDepth(linearDepth, _ZBufferParams);
            float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
            float cameraDistance = - eyeDepth / dot(viewDirWS, cameraForward);
            float dis = cameraDistance * 0.01;
            float disBoost = smoothstep(_FadeFar, _FadeNear, dis) + 0.0001;
            return disBoost;            
        }
#else

        float GetClosenessBoost(float3 viewPos, float depth01)
        {
            viewPos = viewPos * depth01;
            float dis = length (viewPos) * 0.01;
            float disBoost = smoothstep(_BoostFar, _BoostNear, dis) * _ClosenessBoostThickness + 1;
            return disBoost;
        }

        float GetDistanceFade(float3 viewPos, float depth01)
        {            
            viewPos = viewPos * depth01;
            float dis = length (viewPos) * 0.01;
            float disBoost = smoothstep(_FadeFar, _FadeNear, dis) + 0.0001;
            return disBoost;            
        }
#endif

        float MinFloats(float a, float b, float c, float d)
        {
            return min(min(a, b), min(c, d));
        }

        float MaxFloats(float a, float b, float c, float d)
        {
            return max(max(a, b), max(c, d));
        }

        float SampleDepth9Tiles(float2 uv, float3 offset, float3 viewPos, float centerDisBoost, float centerDepth, out float distanceFade)
        {
            offset *= centerDisBoost;

            float d_c = centerDepth;
            float d_l = SampleSceneDepth(saturate(uv - offset.xz));
            float d_r = SampleSceneDepth(saturate(uv + offset.xz));
            float d_u = SampleSceneDepth(saturate(uv + offset.zy));
            float d_d = SampleSceneDepth(saturate(uv - offset.zy));
            float d_lu = SampleSceneDepth(saturate(uv + offset.xy * float2(-1,  1)));
            float d_ld = SampleSceneDepth(saturate(uv + offset.xz * float2(-1, -1)));
            float d_ru = SampleSceneDepth(saturate(uv + offset.xy * float2( 1,  1)));
            float d_rd = SampleSceneDepth(saturate(uv + offset.xy * float2( 1, -1)));

            float d01_c = Linear01Depth(d_c, _ZBufferParams);
            float d01_l = Linear01Depth(d_l, _ZBufferParams);
            float d01_r = Linear01Depth(d_r, _ZBufferParams);
            float d01_u = Linear01Depth(d_u, _ZBufferParams);
            float d01_d = Linear01Depth(d_d, _ZBufferParams); 
            float d01_lu = Linear01Depth(d_lu, _ZBufferParams);
            float d01_ld = Linear01Depth(d_ld, _ZBufferParams);
            float d01_ru = Linear01Depth(d_ru, _ZBufferParams);
            float d01_rd = Linear01Depth(d_rd, _ZBufferParams);

            float de_c = LinearEyeDepth(d_c, _ZBufferParams);
            float de_l = LinearEyeDepth(d_l, _ZBufferParams);
            float de_r = LinearEyeDepth(d_r, _ZBufferParams);
            float de_u = LinearEyeDepth(d_u, _ZBufferParams);
            float de_d = LinearEyeDepth(d_d, _ZBufferParams);
            float de_lu = LinearEyeDepth(d_lu, _ZBufferParams);
            float de_ld = LinearEyeDepth(d_ld, _ZBufferParams);
            float de_ru = LinearEyeDepth(d_ru, _ZBufferParams);
            float de_rd = LinearEyeDepth(d_rd, _ZBufferParams);

            float depthC = de_c;
            float4 depth1 = float4(de_u, de_ru, de_r, de_rd);
            float4 depth2 = float4(de_d, de_ld, de_l, de_lu);
           
            distanceFade = 1;
            if (_EnableDistantFade == 1)
            {
#if UNITY_VERSION >= 202310
                float closeEyeDepth = min(MinFloats(de_l,  de_r,  de_u,  de_d ),
                                                        MinFloats(de_lu, de_ld, de_ru, de_rd));
                closeEyeDepth = min(de_c, closeEyeDepth);
                distanceFade = GetDistanceFadeEyeDepth(viewPos, closeEyeDepth);                
#else
                float closeDepth01 = min(MinFloats(d01_l,  d01_r,  d01_u,  d01_d ),
                                         MinFloats(d01_lu, d01_ld, d01_ru, d01_rd));
                closeDepth01 = min(d01_c, closeDepth01);
                distanceFade = GetDistanceFade(viewPos, closeDepth01);
#endif
                
                
            }

            float diff = MeshEdges(depthC, depth1, depth2);
            diff = smoothstep(_NineTilesThreshold, 1, diff) * distanceFade;

            float uvMask = smoothstep(0.0, _NineTileBottomFix, uv.y);
            diff *= uvMask;
            return diff;
        }

        float SampleDepth5Tiles(float2 uv, float3 offset, float3 viewPos, float centerDisBoost, float centerDepth, out float distanceFade)
        {
            offset *= centerDisBoost;

            float d_c = centerDepth;
            float d_l = SampleSceneDepth(uv - offset.xz);
            float d_r = SampleSceneDepth(uv + offset.xz);
            float d_u = SampleSceneDepth(uv + offset.zy);
            float d_d = SampleSceneDepth(uv - offset.zy);

            float d01_c = Linear01Depth(d_c, _ZBufferParams);
            float d01_l = Linear01Depth(d_l, _ZBufferParams);
            float d01_r = Linear01Depth(d_r, _ZBufferParams);
            float d01_u = Linear01Depth(d_u, _ZBufferParams);
            float d01_d = Linear01Depth(d_d, _ZBufferParams);

            float de_c = LinearEyeDepth(d_c, _ZBufferParams);
            float de_l = LinearEyeDepth(d_l, _ZBufferParams);
            float de_r = LinearEyeDepth(d_r, _ZBufferParams);
            float de_u = LinearEyeDepth(d_u, _ZBufferParams);
            float de_d = LinearEyeDepth(d_d, _ZBufferParams);

            float diffSum = (de_c - de_l) + (de_c - de_r) + (de_c - de_u) + (de_c - de_d);

            distanceFade = 1;
            if (_EnableDistantFade == 1)
            {
#if UNITY_VERSION >= 202310
                float closeEyeDepth = min(de_c, MinFloats(de_l,  de_r,  de_u,  de_d ));
                distanceFade = GetDistanceFadeEyeDepth(viewPos, closeEyeDepth);     
                
#else
                //get the smallest(closest) depth01 arround the center pixel
                float closeDepth01 = min(d01_c , MinFloats(d01_l, d01_r, d01_u, d01_d));
                distanceFade = GetDistanceFade(viewPos, closeDepth01);
#endif
            }

            float result = abs(diffSum) * distanceFade;
            return result;
        }
        ///

#endif
