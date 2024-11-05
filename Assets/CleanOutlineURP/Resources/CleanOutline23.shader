Shader "CR/CleanOutline23"
{
    Properties
    {
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            // RenderType: <None>
            // Queue: <None>
            // DisableBatching: <None>
            "ShaderGraphShader"="false"
            "ShaderGraphTargetId"="UniversalFullscreenSubTarget"
        }
        Pass
        {
 
      
            Name "DrawProcedural"
     
            // Render State
            Cull Off
            Blend Off
            ZTest Off
            ZWrite Off
            
            // Debug
            // <None>
            
            // --------------------------------------------------
            // Pass
            
            HLSLPROGRAM
  #if UNITY_VERSION >= 202310             
            // Pragmas
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            // #pragma enable_d3d11_debug_symbols
            
            /* WARNING: $splice Could not find named fragment 'DotsInstancingOptions' */
            /* WARNING: $splice Could not find named fragment 'HybridV1InjectedBuiltinProperties' */
            
            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>
            
            #define FULLSCREEN_SHADERGRAPH
            
            // Defines
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_VERTEXID
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_TEXCOORD1
            
            // Force depth texture because we need it for almost every nodes
            // TODO: dependency system that triggers this define from position or view direction usage
            #define REQUIRE_DEPTH_TEXTURE
            #define REQUIRE_NORMAL_TEXTURE
            
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DRAWPROCEDURAL
            
            // custom interpolator pre-include
            /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
  
            // Includes
           
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
            //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
            //#include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenShaderPass.cs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
            
            // --------------------------------------------------
            // Structs and Packing
            
            // custom interpolators pre packing
            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
            
            struct Attributes
            {
                #if UNITY_ANY_INSTANCING_ENABLED
                 uint instanceID : INSTANCEID_SEMANTIC;
                #endif
                 uint vertexID : VERTEXID_SEMANTIC;
            };
            struct SurfaceDescriptionInputs
            {
                 float3 WorldSpaceViewDirection;
                 float3 WorldSpacePosition;
                 float4 ScreenPosition;
                 float2 NDCPosition;
                 float2 PixelPosition;
                 float CameraDistance;
            };
            struct Varyings
            {
                 float4 positionCS : SV_POSITION;
                 float4 texCoord0;
                 float4 texCoord1;
                #if UNITY_ANY_INSTANCING_ENABLED
                 uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                 uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                 uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
            };
            struct VertexDescriptionInputs
            {
            };
            struct PackedVaryings
            {
                 float4 positionCS : SV_POSITION;
                 float4 texCoord0 : INTERP0;
                 float4 texCoord1 : INTERP1;
                #if UNITY_ANY_INSTANCING_ENABLED
                 uint instanceID : CUSTOM_INSTANCE_ID;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                 uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                 uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
                #endif
            };
            
            PackedVaryings PackVaryings (Varyings input)
            {
                PackedVaryings output;
                ZERO_INITIALIZE(PackedVaryings, output);
                output.positionCS = input.positionCS;
                output.texCoord0.xyzw = input.texCoord0;
                output.texCoord1.xyzw = input.texCoord1;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                return output;
            }
            
            Varyings UnpackVaryings (PackedVaryings input)
            {
                Varyings output;
                output.positionCS = input.positionCS;
                output.texCoord0 = input.texCoord0.xyzw;
                output.texCoord1 = input.texCoord1.xyzw;
                #if UNITY_ANY_INSTANCING_ENABLED
                output.instanceID = input.instanceID;
                #endif
                #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
                output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
                #endif
                #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
                output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
                #endif
                return output;
            }
        
        
            // --------------------------------------------------
            // Graph
            
            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
            
            float _OutlineThickness;
            float4 _OutlineColor;
            float _EnableClosenessBoost;
            float _ClosenessBoostThickness;
            float _BoostNear;
            float _BoostFar;

            float _EnableDistantFade;
            float _FadeNear;
            float _FadeFar;

            float _DepthCheckMoreSample;
            float _NineTilesThreshold;
            float _NineTileBottomFix;
            float _DepthThickness;
            float _OutlineDepthMultiplier;
            float _OutlineDepthBias;
            float _DepthThreshold;

            float _EnableNormalOutline;
            float _NormalCheckDirection;
            float _NormalThickness;
            float _OutlineNormalMultiplier;
            float _OutlineNormalBias;
            float _NormalThreshold;

            float _DebugMode; //0, off; 1, depth; 2, normal; 3, both

            
            CBUFFER_END
            
            
            // Object and Global properties
            float _FlipY;
            
            // Graph Includes
            // GraphIncludes: <None>
            
            // Graph Functions
            
            TEXTURE2D_X(_BlitTexture);
            float4 Unity_Universal_SampleBuffer_BlitSource_float(float2 uv)
            {
                uint2 pixelCoords = uint2(uv * _ScreenSize.xy);
                return LOAD_TEXTURE2D_X_LOD(_BlitTexture, pixelCoords, 0);
            }
            
            // Custom interpolators pre vertex
            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
            
            // Graph Vertex
            // GraphVertex: <None>
            
            // Custom interpolators, pre surface
            /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreSurface' */

            #include "OutlineCore.hlsl"
            
            // Graph Pixel
            struct SurfaceDescription
            {
                float3 BaseColor;
                float Alpha;
            };
            
            SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
            {
                SurfaceDescription surface = (SurfaceDescription)0;
                float4 baseColor = Unity_Universal_SampleBuffer_BlitSource_float(float4(IN.NDCPosition.xy, 0, 0).xy);
                
                float3 finalColor = baseColor.rgb;
                float2 uv = IN.NDCPosition.xy;

                float depth = SampleSceneDepth(uv);
                float depth01 = Linear01Depth(depth.r, _ZBufferParams);
                float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);

		        //will take consider screen resolution by default
                //you can modify these code to have more manual control
                float screenWidth = _ScreenParams.x;
                float screenHeight = _ScreenParams.y;
                float globalThickness = _OutlineThickness;
                globalThickness *= max(1, screenHeight / 1080);

                ////
                float3 offset = float3((1.0 / screenWidth), (1.0 / screenHeight), 0.0) * globalThickness;
                float3 viewPos = IN.WorldSpaceViewDirection;
                    //(i.viewDir.xyz / i.viewDir.w);

                float centerDisBoost = 1;
                if (_EnableClosenessBoost == 1)
                {                    
                    centerDisBoost = GetClosenessBoostEyeDepth(viewPos, eyeDepth);
                }

                float sobelDepth = 0;
                float distanceFade = 1;
                if (_DepthCheckMoreSample == 1)
                {
                    sobelDepth =  SampleDepth9Tiles(uv, offset * _DepthThickness, viewPos, centerDisBoost, depth.r, distanceFade);
                    sobelDepth = saturate(abs(sobelDepth));
                    sobelDepth = smoothstep(0, _DepthThreshold, sobelDepth) * sobelDepth;
                    sobelDepth = pow(abs(sobelDepth* _OutlineDepthMultiplier), _OutlineDepthBias);
                }
                else
                {
                    sobelDepth = SampleDepth5Tiles(uv, offset * _DepthThickness, viewPos, centerDisBoost, depth.r, distanceFade);
                    sobelDepth = saturate(abs(sobelDepth));
                    sobelDepth = smoothstep(0, _DepthThreshold, sobelDepth) * sobelDepth;
                    sobelDepth = pow(abs(sobelDepth* _OutlineDepthMultiplier), _OutlineDepthBias);
                }

                float isFarAway = step(0.9999999, depth01);
                float3 normalOffset = offset * _NormalThickness * centerDisBoost;
                float sobelNormal = 0;
                if (_EnableNormalOutline == 1)
                {
                    if (_NormalCheckDirection == 1)
                    {
                        sobelNormal = DirectionalSampleNormal(uv, normalOffset);
                        sobelNormal = smoothstep(0, _NormalThreshold, sobelNormal) * sobelNormal;
                        sobelNormal = pow(abs(sobelNormal * _OutlineNormalMultiplier), _OutlineNormalBias);
                    }
                    else
                    {

                        float3 sobelNormalVec = SobelSampleNormal(uv, normalOffset);                                    
                        sobelNormal = sqrt(dot(sobelNormalVec, sobelNormalVec));
                        sobelNormal = smoothstep(0, _NormalThreshold, sobelNormal) * sobelNormal;
                        sobelNormal = pow(abs(sobelNormal * _OutlineNormalMultiplier), _OutlineNormalBias);    
                    
                    }
                }
               
                sobelNormal = saturate(abs(sobelNormal));
                sobelNormal *= distanceFade;

                float outlineStrength = max(sobelNormal, sobelDepth) * (1 - isFarAway) * distanceFade;

                float3 colorCombined = lerp(baseColor.rgb, outlineStrength * _OutlineColor.rgb, outlineStrength);

                if (_DebugMode == 0)
                {
                    finalColor.rgb = colorCombined;
                }
                else if (_DebugMode == 1)
                {
                    finalColor.rgb = sobelDepth;
                }
                else if (_DebugMode == 2)
                {
                    finalColor.rgb = sobelNormal;
                }
                else if (_DebugMode == 3)
                {
                    finalColor.rgb = outlineStrength;
                }

                surface.BaseColor = finalColor.rgb;
                surface.Alpha = 1;
                return surface;
            }
            
            // --------------------------------------------------
            // Build Graph Inputs
            
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
            {
                SurfaceDescriptionInputs output;
                ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
            
                float3 normalWS = SHADERGRAPH_SAMPLE_SCENE_NORMAL(input.texCoord0.xy);
                float4 tangentWS = float4(0, 1, 0, 0); // We can't access the tangent in screen space
            
                float3 viewDirWS = normalize(input.texCoord1.xyz);
                float linearDepth = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(input.texCoord0.xy), _ZBufferParams);
                float3 cameraForward = -UNITY_MATRIX_V[2].xyz;
                float cameraDistance = linearDepth / dot(viewDirWS, cameraForward);
                float3 positionWS = viewDirWS * cameraDistance + GetCameraPositionWS();
            
                output.WorldSpaceViewDirection = normalize(viewDirWS);
            
                output.WorldSpacePosition = positionWS;
                output.ScreenPosition = float4(input.texCoord0.xy, 0, 1);
                output.NDCPosition = input.texCoord0.xy;
                output.CameraDistance = cameraDistance;
            
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign = IS_FRONT_VFACE(input.cullFace, true, false);
            #else
            #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            #endif
            #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
            
                    return output;
            }
        
            // --------------------------------------------------
            // Main
            #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenCommon.hlsl"
            #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/Fullscreen/Includes/FullscreenDrawProcedural.hlsl"
 #endif
            ENDHLSL

        }        
    }
}