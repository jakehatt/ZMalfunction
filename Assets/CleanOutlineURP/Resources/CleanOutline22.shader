Shader "CR/CleanOutline22"
{
    Properties
    {
    }
    SubShader
    {
	    Tags{ "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 100
            ZTest Off ZWrite Off Cull Off

        Pass
        {
            Name "Clean Outline"
        			
			HLSLPROGRAM
			
  #if UNITY_VERSION >= 202230   
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			
			
			struct AttributesExtra
			{
			    uint vertexID : SV_VertexID;
			    UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct VaryingsExtra
			{
			    float4 positionCS : SV_POSITION;
			    float2 texcoord   : TEXCOORD0;
				float4 viewDir : TEXCOORD1;
			    UNITY_VERTEX_OUTPUT_STEREO
			};
			

			// CBUFFER_START(UnityPerMaterial)
			// float4 _MainTex_ST;
			// CBUFFER_END
			//
			// TEXTURE2D(_MainTex);
			// SAMPLER(sampler_MainTex);
			
			#pragma vertex VertExtra
			#pragma fragment FragExtra
			
			TEXTURE2D(_CameraColorTexture);
			SAMPLER(sampler_CameraColorTexture);

			VaryingsExtra VertExtra(AttributesExtra input)
			{
			    VaryingsExtra output;
			    UNITY_SETUP_INSTANCE_ID(input);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
			
			#if SHADER_API_GLES
			    float4 pos = input.positionOS;
			    float2 uv  = input.uv;
			#else
			    float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
			    float2 uv  = GetFullScreenTriangleTexCoord(input.vertexID);
			#endif
			
			    output.positionCS = pos;
			    output.texcoord   = uv * _BlitScaleBias.xy + _BlitScaleBias.zw;
				output.viewDir = mul (unity_CameraInvProjection, float4 (output.texcoord * 2.0 - 1.0, 1.0, 1.0));
			    return output;
			}
	     
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

			#include "OutlineCore.hlsl"

			
			
			half4 FragExtra(VaryingsExtra input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

				//float2 uv = i.uv;
          		//half4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);
				half4 baseColor = SAMPLE_TEXTURE2D(_CameraColorTexture,sampler_CameraColorTexture, uv);

				float3 finalColor = baseColor.rgb;
				//return float4(1, 0, 0, 1);

                float depth = SampleSceneDepth(uv);
                float depth01 = Linear01Depth(depth.r, _ZBufferParams);

		        //will take consider screen resolution by default
                //you can modify these code to have more manual control
                float screenWidth = _ScreenParams.x;
                float screenHeight = _ScreenParams.y;
                float globalThickness = _OutlineThickness;
                globalThickness *= max(1, screenHeight / 1080);

                ////
                float3 offset = float3((1.0 / screenWidth), (1.0 / screenHeight), 0.0) * globalThickness;
                float3 viewPos = (input.viewDir.xyz / input.viewDir.w);

                float centerDisBoost = 1;
                if (_EnableClosenessBoost == 1)
                {
                    centerDisBoost = GetClosenessBoost(viewPos, depth01);
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
                float isFarAway = step(0.9999999, depth01);
               
                sobelNormal = saturate(abs(sobelNormal)) * (1 - isFarAway);
                sobelNormal *= distanceFade;

                sobelDepth *= distanceFade;
				
                float outlineStrength = max(sobelNormal, sobelDepth);

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
			    return float4(finalColor.rgb, 1);
			}
	#endif
			ENDHLSL
        }
    }
}