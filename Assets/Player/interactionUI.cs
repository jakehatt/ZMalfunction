using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

using TMPro;

public class interactionUI : MonoBehaviour
{
       private Queue<Vector2> positionBuffer = new Queue<Vector2>();
    private Queue<Vector2> sizeBuffer = new Queue<Vector2>();
    public int bufferSize = 5;
  
    public float margin = 10f;

    private Vector2 velocityPosition;
    private Vector2 velocitySize;
    public float smoothTime = 0.1f;
    [SerializeField] Camera cam;
    [SerializeField] float interactRange;
    [SerializeField] RectTransform recVec;

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
      defaultPos = recVec.localPosition;
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


             Noun.text ="> "+ targetInteract.Basics.interactNoun;
          



        }
        else if  (targetInteract!=null)
        {
            recVec.localPosition = defaultPos;
           StartCoroutine(waitToWipeSelected());
        }

    }
    void LateUpdate() // Change from Update to LateUpdate
{
    UpdateInteractionUI();
}

void UpdateInteractionUI()
{
    if (targetInteract != null)
    {
        DrawAroundSelected(targetInteract.gameObject);
    }
}
 void DrawAroundSelected(GameObject target)
    {
        MeshRenderer meshRenderer = target.GetComponent<MeshRenderer>();
        if (meshRenderer == null) return;

        Bounds bounds = meshRenderer.bounds;

        // Calculate the center of the bounds in screen space
        Vector3 centerScreenPosition = Camera.main.WorldToScreenPoint(bounds.center);

        // Calculate screen space bounds for the corners with margin
        Vector3[] screenCorners = new Vector3[8];
        screenCorners[0] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.min.y, bounds.min.z));
        screenCorners[1] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.min.y, bounds.min.z));
        screenCorners[2] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.max.y, bounds.min.z));
        screenCorners[3] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.min.y, bounds.max.z));
        screenCorners[4] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.max.y, bounds.min.z));
        screenCorners[5] = Camera.main.WorldToScreenPoint(new Vector3(bounds.min.x, bounds.max.y, bounds.max.z));
        screenCorners[6] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.min.y, bounds.max.z));
        screenCorners[7] = Camera.main.WorldToScreenPoint(new Vector3(bounds.max.x, bounds.max.y, bounds.max.z));

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

        minX -= margin;
        maxX += margin;
        minY -= margin;
        maxY += margin;

        Vector2 size = new Vector2(maxX - minX, maxY - minY);

        // Calculate the position for the center of the bounding box
        Vector2 screenPosition = new Vector2(centerScreenPosition.x, centerScreenPosition.y);

        if (recVec != null && canvas != null)
        {
            RectTransform canvasRectTransform = canvas.GetComponent<RectTransform>();

            // Set the pivot to the center
            recVec.pivot = new Vector2(0.5f, 0.5f);

            // Convert screen position to local position within the canvas
            Vector2 localPosition;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(canvasRectTransform, screenPosition, canvas.worldCamera, out localPosition);

            // Add to buffers
            positionBuffer.Enqueue(localPosition);
            sizeBuffer.Enqueue(size);

            if (positionBuffer.Count > bufferSize) positionBuffer.Dequeue();
            if (sizeBuffer.Count > bufferSize) sizeBuffer.Dequeue();

            // Average the buffered positions and sizes
            Vector2 averagePosition = new Vector2(positionBuffer.Average(p => p.x), positionBuffer.Average(p => p.y));
            Vector2 averageSize = new Vector2(sizeBuffer.Average(s => s.x), sizeBuffer.Average(s => s.y));

            // Smoothly move and resize the RectTransform with SmoothDamp
            recVec.localPosition = averagePosition;            recVec.sizeDelta = averageSize;
        }
    }
public IEnumerator waitToWipeSelected(){
    yield return new WaitForSeconds(0.1F);
     RaycastHit hit;
     if (Physics.Raycast(new Vector3(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z), cam.transform.forward, out hit, interactRange) && (hit.transform.gameObject.GetComponent<Interactable>() == null)||!Physics.Raycast(new Vector3(cam.transform.position.x, cam.transform.position.y, cam.transform.position.z), cam.transform.forward, out hit, interactRange ) ){

 recVec.position = defaultPos;
            targetInteract = null;
            recVec.gameObject.active = false;
     }
}

}

