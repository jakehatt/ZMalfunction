using CR;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using ProfilingScope = UnityEngine.Rendering.ProfilingScope;

namespace CR
{
    class CleanOutlineRenderPass : ScriptableRenderPass
    {
        const string Tag = "CleanOutline Post Process";
#if UNITY_2023_1_OR_NEWER
        private RTHandle m_Source;
        private RTHandle m_TempDest;
#elif UNITY_2022_3_OR_NEWER
        private RTHandle m_Source;
        private RTHandle m_TempDest;
#else
        private RenderTargetIdentifier m_Source;
        private RenderTargetHandle m_TempDest;
#endif
        private CleanOutline m_Volume;
        private Material m_CleanOutlineMaterial;
        
        private ProfilingSampler m_ProfilingSampler;
        
        private int OUTLINETHICKNESS_ID = Shader.PropertyToID("_OutlineThickness");
        private int OUTLINECOLOR_ID = Shader.PropertyToID("_OutlineColor");
        private int ENABLECLOSENESSBOOST_ID = Shader.PropertyToID("_EnableClosenessBoost");
        private int CLOSENESSBOOSTTHICKNESS_ID = Shader.PropertyToID("_ClosenessBoostThickness");
        private int BOOSTNEAR_ID = Shader.PropertyToID("_BoostNear");
        private int BOOSTFAR_ID = Shader.PropertyToID("_BoostFar");
        private int ENABLEDISTANTFADE_ID = Shader.PropertyToID("_EnableDistantFade");
        private int FADENEAR_ID = Shader.PropertyToID("_FadeNear");
        private int FADEFAR_ID = Shader.PropertyToID("_FadeFar");
        private int DEPTHCHECKMORESAMPLE_ID = Shader.PropertyToID("_DepthCheckMoreSample");
        private int NINETILESTHRESHOLD_ID = Shader.PropertyToID("_NineTilesThreshold");
        private int NINETILEBOTTOMFIX_ID = Shader.PropertyToID("_NineTileBottomFix");
        private int DEPTHTHICKNESS_ID = Shader.PropertyToID("_DepthThickness");
        private int OUTLINEDEPTHMULTIPLIER_ID = Shader.PropertyToID("_OutlineDepthMultiplier");
        private int OUTLINEDEPTHBIAS_ID = Shader.PropertyToID("_OutlineDepthBias");
        private int DEPTHTHRESHOLD_ID = Shader.PropertyToID("_DepthThreshold");
        private int ENABLENORMALOUTLINE_ID = Shader.PropertyToID("_EnableNormalOutline");
        private int NORMALCHECKDIRECTION_ID = Shader.PropertyToID("_NormalCheckDirection");
        private int NORMALTHICKNESS_ID = Shader.PropertyToID("_NormalThickness");
        private int OUTLINENORMALMULTIPLIER_ID = Shader.PropertyToID("_OutlineNormalMultiplier");
        private int OUTLINENORMALBIAS_ID = Shader.PropertyToID("_OutlineNormalBias");
        private int NORMALTHRESHOLD_ID = Shader.PropertyToID("_NormalThreshold");
        private int DEBUGMODE_ID = Shader.PropertyToID("_DebugMode");

        private int BLITTEXTURE = Shader.PropertyToID("_BlitTexture");

        public CleanOutlineRenderPass(CleanOutline volume)
        {
            m_Volume = volume;
        }

        public void Setup(in RenderingData renderingData)
        {
            m_ProfilingSampler ??= new ProfilingSampler(Tag);
#if UNITY_2023_1_OR_NEWER
            var colorCopyDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            colorCopyDescriptor.depthBufferBits = (int)DepthBits.None;
            RenderingUtils.ReAllocateIfNeeded(ref m_TempDest, colorCopyDescriptor, name: "_CleanOutlineTemp");
#endif
        }

        public void Dispose()
        {
#if UNITY_2023_1_OR_NEWER
            m_TempDest?.Release();
#elif UNITY_2022_3_OR_NEWER
            m_TempDest?.Release();
#endif
        }

        public void InitMaterialIfNeeded()
        {
            if (m_CleanOutlineMaterial == null)
            {
#if UNITY_2023_1_OR_NEWER
                m_CleanOutlineMaterial = new Material(Shader.Find("CR/CleanOutline23"));
                //ConfigureInput(ScriptableRenderPassInput.Normal ^ ScriptableRenderPassInput.Color ^ ScriptableRenderPassInput.Depth);
#elif UNITY_2022_3_OR_NEWER
                m_CleanOutlineMaterial = new Material(Shader.Find("CR/CleanOutline22"));
#else
                m_CleanOutlineMaterial = new Material(Shader.Find("CR/CleanOutline"));
#endif
            }
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.cameraType == CameraType.Reflection ||
                renderingData.cameraData.camera.cameraType == CameraType.SceneView)
                return;
            
#if UNITY_2023_1_OR_NEWER
            m_Source = renderingData.cameraData.renderer.cameraColorTargetHandle;
#elif UNITY_2022_3_OR_NEWER            
            m_Source = renderingData.cameraData.renderer.cameraColorTargetHandle;
#else
            m_Source = renderingData.cameraData.renderer.cameraColorTarget;
#endif
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            // Set the number of depth bits we need for our temporary render texture.
            descriptor.depthBufferBits = 0;
            InitMaterialIfNeeded();
            ConfigureInput(ScriptableRenderPassInput.Normal);          
#if UNITY_2023_1_OR_NEWER

#elif UNITY_2022_3_OR_NEWER
            RenderingUtils.ReAllocateIfNeeded(ref m_TempDest, descriptor, name: "_CleanOutlineTemp");
#else
            m_TempDest.Init("_CleanOutlineTemp");
#endif
       }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.camera.cameraType != CameraType.Game)
                return;

            CommandBuffer cmd = CommandBufferPool.Get("CleanOutline");
            using (new ProfilingScope(cmd, profilingSampler))
            {
                //m_Volume might be set to null after switching scene
                if (m_Volume == null)
                {
                    var volumeStack = VolumeManager.instance.stack;
                    m_Volume = volumeStack.GetComponent<CleanOutline>();
                }

                InitMaterialIfNeeded();

                if (m_Volume != null && m_Volume.standaloneActive.value)
                {
                    //general
                    m_CleanOutlineMaterial.SetFloat(OUTLINETHICKNESS_ID, m_Volume.outlineThickness.value);
                    m_CleanOutlineMaterial.SetColor(OUTLINECOLOR_ID, m_Volume.outlineColor.value);


                    m_CleanOutlineMaterial.SetFloat(ENABLECLOSENESSBOOST_ID,
                        m_Volume.enableClosenessBoost.value ? 1 : 0);
                    m_CleanOutlineMaterial.SetFloat(CLOSENESSBOOSTTHICKNESS_ID, m_Volume.closenessBoostThickness.value);
                    m_CleanOutlineMaterial.SetFloat(BOOSTNEAR_ID, m_Volume.closenessBoostNear.value);
                    m_CleanOutlineMaterial.SetFloat(BOOSTFAR_ID, m_Volume.closenessBoostFar.value);

                    m_CleanOutlineMaterial.SetFloat(ENABLEDISTANTFADE_ID, m_Volume.enableDistanceFade.value ? 1 : 0);
                    m_CleanOutlineMaterial.SetFloat(FADENEAR_ID, m_Volume.distanceFadeNear.value);
                    m_CleanOutlineMaterial.SetFloat(FADEFAR_ID, m_Volume.distanceFadeFar.value);

                    //depth
                    m_CleanOutlineMaterial.SetFloat(DEPTHCHECKMORESAMPLE_ID,
                        (m_Volume.depthSampleType.value == CleanOutlineDepthSample.NineTiles) ? 1 : 0);
                    m_CleanOutlineMaterial.SetFloat(DEPTHTHICKNESS_ID, m_Volume.depthThickness.value);

                    m_CleanOutlineMaterial.SetFloat(DEPTHTHRESHOLD_ID, m_Volume.depthThreshold.value);

                    m_CleanOutlineMaterial.SetFloat(OUTLINEDEPTHMULTIPLIER_ID, m_Volume.depthMultiplier.value);
                    m_CleanOutlineMaterial.SetFloat(OUTLINEDEPTHBIAS_ID, m_Volume.depthBias.value);
                    m_CleanOutlineMaterial.SetFloat(NINETILESTHRESHOLD_ID, m_Volume.depth9TilesThreshold.value);
                    m_CleanOutlineMaterial.SetFloat(NINETILEBOTTOMFIX_ID, m_Volume.depth9TilesBottomFix.value);

                    //normal
                    m_CleanOutlineMaterial.SetFloat(ENABLENORMALOUTLINE_ID, m_Volume.enableNormalOutline.value ? 1 : 0);
                    m_CleanOutlineMaterial.SetFloat(NORMALTHICKNESS_ID, m_Volume.normalThickness.value);
                    m_CleanOutlineMaterial.SetFloat(OUTLINENORMALMULTIPLIER_ID, m_Volume.normalMultiplier.value);
                    m_CleanOutlineMaterial.SetFloat(OUTLINENORMALBIAS_ID, m_Volume.normalBias.value);
                    m_CleanOutlineMaterial.SetFloat(NORMALTHRESHOLD_ID, m_Volume.normalThreshold.value);
                    m_CleanOutlineMaterial.SetFloat(NORMALCHECKDIRECTION_ID,
                        m_Volume.normalCheckDirection.value ? 1 : 0);

                    //debug
                    m_CleanOutlineMaterial.SetFloat(DEBUGMODE_ID, (float)m_Volume.debugMode.value);
#if UNITY_2023_1_OR_NEWER
                    Blitter.BlitCameraTexture(cmd, m_Source, m_TempDest);
                    m_CleanOutlineMaterial.SetTexture(BLITTEXTURE, m_TempDest);

                    CoreUtils.SetRenderTarget(cmd, renderingData.cameraData.renderer.cameraColorTargetHandle);
                    CoreUtils.DrawFullScreen(cmd, m_CleanOutlineMaterial);
#elif UNITY_2022_3_OR_NEWER
                    Blitter.BlitTexture(cmd, m_Source, m_TempDest, m_CleanOutlineMaterial, 0);
                    Blitter.BlitCameraTexture(cmd, m_TempDest, m_Source);
#else
                    RenderTextureDescriptor cameraTexDesc = renderingData.cameraData.cameraTargetDescriptor;
                    cmd.GetTemporaryRT(m_TempDest.id, cameraTexDesc, FilterMode.Point);
                    Blit(cmd, m_Source, m_TempDest.Identifier(), m_CleanOutlineMaterial);
                    Blit(cmd, m_TempDest.Identifier(), m_Source);
#endif
                }
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        { 
#if UNITY_2023_1_OR_NEWER
#elif UNITY_2022_3_OR_NEWER
#else
            cmd.ReleaseTemporaryRT(m_TempDest.id);
#endif
        }
    }

    public class CleanOutlineRenderPassFeature : ScriptableRendererFeature
    {
        CleanOutlineRenderPass m_ScriptablePass;

        private CleanOutline m_CleanOutlineVolume;

        /// <inheritdoc/>
        public override void Create()
        {
            m_CleanOutlineVolume = VolumeManager.instance.stack.GetComponent<CleanOutline>();

            m_ScriptablePass = new CleanOutlineRenderPass(m_CleanOutlineVolume);
         
            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {  
            m_ScriptablePass.Setup(renderingData);
            renderer.EnqueuePass(m_ScriptablePass);
        }
        
        protected override void Dispose(bool disposing)
        {
            m_ScriptablePass.Dispose();
        }
    }
}

