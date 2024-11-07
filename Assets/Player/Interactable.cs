using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using AC;
using UnityEngine;

public class Interactable : MonoBehaviour


{
    [SerializeField] Hotspot hotspot;
    public interactBasics Basics;
    public interactCaption interactCaption;
    public interactLift interactLift;
    public bool isHighlighted = false;
    interactionUI reticle;
    Camera cam;
    bool isLifting = false;
    GameObject player;
    



    // Start is called before the first frame update
    void Start()
    {
        if (hotspot !=null){
            Basics.interactNoun = hotspot.name;
        }
        cam = Camera.main;
        player = FindObjectOfType<FirstPersonMovement>().gameObject;
        reticle = FindObjectOfType<interactionUI>();
        Basics.colour.a = 1;
    }

    // Update is called once per frame
    void Update()
    {
        
        if (!Basics.isCrime)
        {
            Basics.colour = Color.white;
        }
        else
        {
            Basics.colour = new Color(1f, 0.1f, 0.1f, 1);
        }
        if (!isLifting){
        if (Input.GetButtonDown("Interact") && reticle.targetInteract == this)
        {

          
            switch (Basics.InteractType)
            {
                case interactBasics.interactType.Consume:
                    Destroy(gameObject);
                    break;
                    case interactBasics.interactType.Lift:
                    isLifting = true;
                    break;
                    case interactBasics.interactType.Drop:
                    isLifting = false;
                     Basics.InteractType = interactBasics.interactType.Lift;
                    break;
                      case interactBasics.interactType.Use:
                   hotspot.RunUseInteraction();
                  
                 
                    break;
            }
        }
        }
        else if (Input.GetButtonDown("Interact")){
             Basics.InteractType = interactBasics.interactType.Lift;
             isLifting = false;
        }
      //  else if (Input.GetButtonDown("Throw")){
       //  Basics.InteractType = interactBasics.interactType.Lift;
     //       isLifting = false;
           
     //   }
           else if (Vector3.Distance(player.transform.position, transform.position) > interactLift.distFromCam*2){
         Basics.InteractType = interactBasics.interactType.Lift;
            isLifting = false;
           
        }
    }
    void LateUpdate(){
        if (isLifting){
            liftObject();
        }
    }
    void liftObject()
    {
       
        Rigidbody rb = GetComponent<Rigidbody>();
        if (rb != null)
        {
            Basics.InteractType = interactBasics.interactType.Drop;
            Vector3 moveto = cam.transform.position + (cam.transform.forward * interactLift.distFromCam);
            Vector3 vecdirec = (rb.gameObject.transform.position - moveto).normalized;
       
            float dis = Vector3.Distance(rb.gameObject.transform.position, moveto);
            rb.velocity = (-vecdirec * Mathf.SmoothStep(0, 20, dis)*dis) + player.GetComponent<Rigidbody>().velocity;
            Vector3 rbForward = rb.transform.forward;
            Vector3 torqueXZ = Vector3.Cross(cam.transform.forward, rbForward);
            Vector3 torqueY = Vector3.Project(torqueXZ*12, Vector3.up);
             var springTorque = 9 * Vector3.Cross(rb.transform.up, Vector3.up);
             Vector3 torqueXYZ = torqueY + springTorque;
              var dampTorque = 4 * -rb.angularVelocity;
            rb.AddTorque(torqueXYZ + dampTorque);

        }
    }
}


[System.Serializable]
public class interactBasics
{
    public enum interactType { Look,  Consume, Inv, Lift, Drop,  Use};
    public interactType InteractType = new interactType();
    public string interactNoun;
    public bool isCrime;


    public Color colour;
}


[System.Serializable]
public class interactCaption
{
    public string caption;
}


[System.Serializable]
public class interactLift{
 public float distFromCam = 3f;
 public int strengthCheck = 0;



}