#if UNITY_EDITOR

using UnityEditor;

namespace AC
{

	public class ToolbarLinksDemo : EditorWindow
	{

		[MenuItem ("Adventure Creator/Getting started/Load 3D Demo", false, 6)]
		static void Demo3D ()
		{
			AdventureCreator.RefreshActions ();

			if (!ACInstaller.IsInstalled ())
			{
				ACInstaller.DoInstall ();
			}

			if (UnityVersionHandler.GetCurrentSceneName () != "Basement")
			{
				if (UnityVersionHandler.SaveSceneIfUserWants ())
				{
					UnityEditor.SceneManagement.EditorSceneManager.OpenScene ("Assets/AdventureCreator/Demo/Scenes/Basement.unity");
				}
			}

			AdventureCreator.Init ();
		}

	}

}

#endif