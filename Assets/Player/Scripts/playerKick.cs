using System.Collections;
using System.Collections.Generic;

using UnityEngine;

public class playerKick : MonoBehaviour
{
    Animator anim;
    Camera cam;
    [SerializeField] SkinnedMeshRenderer meshR;
    [SerializeField] float kickRange = 4f;
    [SerializeField] float kickPhysicsStrength = 500f;
    [SerializeField] CharacterController player;
    // Start is called before the first frame update
    void Start()
    {
        meshR.enabled = false;
        anim = GetComponent<Animator>();
        cam = Camera.main;

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetButton("Kick"))
        {
            anim.SetBool("KickL", true);
        }
    }
    void KickReset()
    {
        meshR.enabled = false;
        anim.SetBool("KickL", false);
    }
    void KickStart()
    {
        meshR.enabled = true;

    }
    void KickConnect()
    {
        RaycastHit hit;
        if (Physics.Raycast(new Vector3(cam.transform.position.x,cam.transform.position.y - 0.15f,cam.transform.position.z), cam.transform.forward, out hit, kickRange))
        {
            
            if (hit.rigidbody != null)
            {
                hit.rigidbody.AddForce((hit.point -player.transform.position).normalized* kickPhysicsStrength, ForceMode.Impulse);
            }
        }
    }
}

