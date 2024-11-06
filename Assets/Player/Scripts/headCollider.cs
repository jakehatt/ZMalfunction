using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class headCollider : MonoBehaviour
{
   public bool isColliding = false;
    // Start is called before the first frame update
   
   private void OnTriggerEnter(Collider other) {
    
        isColliding = true;
        print("collide");
    

   }
private void OnTriggerExit(Collider other) {
    

   
        isColliding = false;
}
}
