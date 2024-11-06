#if UNITY_EDITOR

using UnityEditor;

namespace AC
{

	public class ToolbarLinks2DDemo : EditorWindow
	{

		[MenuItem ("Adventure Creator/Getting started/Load 2D Demo", false, 5)]
		static void Demo2D ()
		{
			AdventureCreator.RefreshActions ();

			if (!ACInstaller.IsInstalled ())
			{
				ACInstaller.DoInstall ();
			}

			if (UnityVersionHandler.GetCurrentSceneName () != "Park")
			{
				if (UnityVersionHandler.SaveSceneIfUserWants ())
				{
					UnityEditor.SceneManagement.EditorSceneManager.OpenScene ("Assets/AdventureCreator/2D Demo/Scenes/Park.unity");
				}
			}

			AdventureCreator.Init ();
		}

	}

}

#endif