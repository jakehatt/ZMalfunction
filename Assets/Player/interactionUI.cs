using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;

using UnityEditor.PackageManager;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

using TMPro;

public class interactionUI : MonoBehaviour
{
    [SerializeField] Camera cam;
    [SerializeField] float interactRange;
    [SerializeField] RectTransform recVec;
    public float margin = 0;
    [SerializeField] TextMeshProUGUI Verb;
  [SerializeField] TextMeshProUGUI Noun;
  [SerializeField] Canvas canvas;
    [SerializeField] public Interactable targetInteract;

      [SerializeField] Image c1;
     [SerializeField] Image c2;
     
     [SerializeField]  Image c3;
     [SerializeField] Image c4;
    // Start is called before the first frame update
      Vector3 defaultPos;

    void Start()
    {
      defaultPos = Vector3.zero;
          cam = Camera.main;
        RectTransform rt = recVec;
    }

    // Update is called once per frame
    void Update()
    {
        RaycastHit hit;
        if ((Physics.Raycast(new Vector3(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z), cam.transform.forward, out hit, interactRange)) && (hit.transform.gameObject.GetComponent<Interactable>() != null))
        {

      

            recVec.gameObject.active = true;
             targetInteract = hit.transform.gameObject.GetComponent<Interactable>();


             Verb.text ="> "+ targetInteract.Basics.interactVerb;
          



        }
        else if  (targetInteract!=null)
        {
           StartCoroutine(waitToWipeSelected());
        }

    }
    void FixedUpdate() // Change from Update to LateUpdate
{
    UpdateInteractionUI();
}

void UpdateInteractionUI()
{
    if (targetInteract != null)
    {
        drawAroundSelected(targetInteract.gameObject);
    }
}
void drawAroundSelected(GameObject target)
{
    MeshRenderer meshRenderer = target.GetComponent<MeshRenderer>();
    if (meshRenderer == null) return;

    // Get world bounds of the object
    Bounds bounds = meshRenderer.bounds;

    // Calculate screen space for each corner of the bounds
    Vector3[] screenCorners = new Vector3[8];
    screenCorners[0] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.min.y, bounds.min.z));
    screenCorners[1] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.min.y, bounds.min.z));
    screenCorners[2] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.max.y, bounds.min.z));
    screenCorners[3] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.min.y, bounds.max.z));
    screenCorners[4] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.max.y, bounds.min.z));
    screenCorners[5] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.max.y, bounds.max.z));
    screenCorners[6] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.min.y, bounds.max.z));
    screenCorners[7] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.max.y, bounds.max.z));

    // Find min and max bounds in screen space
    float minX = screenCorners[0].x;
    float maxX = screenCorners[0].x;
    float minY = screenCorners[0].y;
    float maxY = screenCorners[0].y;

    foreach (Vector3 corner in screenCorners)
    {
        if (corner.x < minX) minX = corner.x;
        if (corner.x > maxX) maxX = corner.x;
        if (corner.y < minY) minY = corner.y;
        if (corner.y > maxY) maxY = corner.y;
    }

    // Add a margin to the selection box (this controls the padding around the target)
    minX -= margin;
    maxX += margin;
    minY -= margin;
    maxY += margin;

    // Clamp the min/max coordinates to stay within the canvas bounds
    RectTransform canvasRect = canvas.GetComponent<RectTransform>();
    minX = Mathf.Clamp(minX, 0, canvasRect.rect.width - (maxX - minX));
    maxX = Mathf.Clamp(maxX, minX, canvasRect.rect.width);
    minY = Mathf.Clamp(minY, 0, canvasRect.rect.height - (maxY - minY));
    maxY = Mathf.Clamp(maxY, minY, canvasRect.rect.height);

    // Calculate the final size and position
    Vector2 size = new Vector2(maxX - minX, maxY - minY);
    Vector2 screenPosition = new Vector2(minX, minY);

    if (recVec != null && canvas != null)
    {
        RectTransform canvasRectTransform = canvas.GetComponent<RectTransform>();

        // Convert screen position to local position within the canvas
        Vector2 localPosition;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasRectTransform, screenPosition, canvas.worldCamera, out localPosition);

        // Apply smooth transition to the RectTransform's position and size
        recVec.localPosition = Vector2.Lerp(recVec.localPosition, localPosition, Time.deltaTime * Vector2.Distance(recVec.localPosition, localPosition)/10);  // Adjust speed for smoother movement
        recVec.sizeDelta = Vector2.Lerp(recVec.sizeDelta, size, Time.deltaTime * Vector2.Distance(recVec.sizeDelta, canvasRectTransform.sizeDelta)/10);  // Smooth the resizing as well
    }
}


    public static Vector2 WorldToGUIPoint(Vector3 world)
    {
        Vector2 screenPoint = Camera.main.WorldToScreenPoint(world);
        screenPoint.y = (float)Screen.height - screenPoint.y;
        return screenPoint;
    }

public IEnumerator waitToWipeSelected(){
    yield return new WaitForSeconds(0.2f);
     RaycastHit hit;
     if (Physics.Raycast(new Vector3(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z), cam.transform.forward, out hit, interactRange) && (hit.transform.gameObject.GetComponent<Interactable>() == null)||!Physics.Raycast(new Vector3(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z), cam.transform.forward, out hit, interactRange ) ){

 recVec.position = defaultPos;
            targetInteract = null;
            recVec.gameObject.active = false;
     }
}

}

