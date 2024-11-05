Shader "CR/CleanOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
    	Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
         
        LOD 100
        //ZTest Always ZWrite Off Cull Off
    	ZTest Off ZWrite Off Cull Off

        Pass
        {
            Name "Clean Outline"

			HLSLINCLUDE
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			ENDHLSL
            			
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			struct a2v
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float4 viewDir : TEXCOORD1;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			CBUFFER_END

			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.positionOS.xyz);
				o.uv = v.uv;
			    o.viewDir = mul (unity_CameraInvProjection, float4 (o.uv * 2.0 - 1.0, 1.0, 1.0));
				return o;
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
			
			half4 frag(v2f i) : SV_Target
			{
				float2 uv = i.uv;
          		half4 baseColor = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, i.uv);

				float3 finalColor = baseColor.rgb;

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
                float3 viewPos = (i.viewDir.xyz / i.viewDir.w);

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
			ENDHLSL
        }
    }
}
