using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.Common;
using UnityEngine;

public class playerMovement : MonoBehaviour
{
  CharacterController player;
  [Header("Movement")]
  [SerializeField] float pushForce = 5f;
  [SerializeField] float playerSpeed = 1f;

  [SerializeField] float sprintMult = 1.3f;
  float currentSprintMult = 1f;
  [Range(60f, 120f)][SerializeField] float normalFOV = 90f;
  [Range(60f, 120f)][SerializeField] float sprintFOV = 110f;
  [SerializeField] float sprintAcceleration = 3f;
  [Header("Look")]
  public float lookSpeed = 3f;
  private Vector2 rotation = Vector2.zero;

  [Header("Jump")]
  [SerializeField] float sprintJumpMult = 1.5f;
  float currentSprintJumpMult;
  [SerializeField] float jumpHeight = 1f;
  [SerializeField] int coyoteTime = 3;
  [SerializeField] bool wasGroundedRecently = false;

  [SerializeField] float gravityValue = -5f;


  private Vector3 playerVelocity;
  bool groundedPlayer;

  [Header("Sneak")]
  [SerializeField] float sneakHeight = 1f;
  [SerializeField] bool isSneaking;
  [SerializeField] float crouchJumpMult;
  float currentCrouchJumpMult;
  Vector3 baseheight;
  private float currentSneakMult;
  [SerializeField] float sneakMult;
  float sneakYvec;



  [Header("Peek")]

  [SerializeField] GameObject cameraPivot;
  Camera cam;
  headCollider head;
  [SerializeField] float peekAmount = 20f;
  [SerializeField] float peekSpeed = 20f;



  // Start is called before the first frame update
  void Start()
  {
    cam = Camera.main;

    baseheight = cam.transform.localPosition;
    head = cam.gameObject.GetComponent<headCollider>();
    player = GetComponent<CharacterController>();
  }
  // Update is called once per frame
  void Update()
  {
    groundedPlayer = player.isGrounded;
    Cursor.lockState = CursorLockMode.Locked;
    Cursor.visible = false;


    XYZ_Movement();
    Look();
    Sneak();
    Peek();


    Sprint();







  }
  private IEnumerator CoyoteTime(int seconds)
  {

    int counter = seconds;
    while (counter > 0)
    {
      yield return new WaitForSeconds(0.1f);
      counter--;

    }

    wasGroundedRecently = false;


  }

  void XYZ_Movement()
  {

    float h = Input.GetAxisRaw("Horizontal");
    float v = Input.GetAxisRaw("Vertical");
    Vector3 horiz = h * player.transform.right;
    Vector3 vert = v * player.transform.forward;
    Vector3 moveVec = (horiz + vert).normalized;
    moveVec.y = 0;
    Vector3 XZ_Move = moveVec * playerSpeed * currentSprintMult * currentSneakMult;

    if (groundedPlayer)
    {
      StopCoroutine("CoyoteTime");
      wasGroundedRecently = true;

      if (playerVelocity.y < 0)
      {
        playerVelocity.y = 0f;
      }

    }
    else
    {
      StartCoroutine(CoyoteTime(coyoteTime));
    }
    if (Input.GetButtonDown("Jump") && wasGroundedRecently)
    {
      wasGroundedRecently = false;
      playerVelocity.y += Mathf.Sqrt(jumpHeight * -3.0f * gravityValue * currentSprintJumpMult * currentCrouchJumpMult);
    }

    playerVelocity.y += gravityValue * Time.deltaTime;
    player.Move(new Vector3(XZ_Move.x, playerVelocity.y, XZ_Move.z) * Time.deltaTime);

    sneakYvec = Mathf.SmoothStep(cam.transform.localPosition.y, baseheight.y, 0.3f);
    isSneaking = false;
    currentSneakMult = 1;


  }
  void Look()
  {

    rotation.y += Input.GetAxis("Mouse X");
    rotation.x += -Input.GetAxis("Mouse Y");
    rotation.x = Mathf.Clamp(rotation.x, -28f, 28f);
    player.transform.eulerAngles = new Vector2(0, rotation.y) * lookSpeed;
    cam.transform.localRotation = Quaternion.Euler(rotation.x * lookSpeed, 0, 0);
  }



  void Sprint()
  {

    if (Input.GetButton("Sprint") && player.velocity.magnitude > 3f && !isSneaking)
    {

      currentSprintMult = Mathf.SmoothStep(currentSprintMult, sprintMult, sprintAcceleration);

      cam.fieldOfView = Mathf.SmoothStep(cam.fieldOfView, sprintFOV, sprintAcceleration);
      currentSprintJumpMult = sprintJumpMult;


    }
    else
    {
      currentSprintMult = Mathf.SmoothStep(currentSprintMult, 1, sprintAcceleration);
      cam.fieldOfView = Mathf.SmoothStep(cam.fieldOfView, normalFOV, sprintAcceleration / 2);
      currentSprintJumpMult = 1;
    }
  }


  void Peek()
  {
    float rayMult = 1;
    float VerticalCameraMult = 1;

    //raycast to figure out how far head is from colliding with an object
    if (Input.GetAxisRaw("Peek") != 0)
    {
    
      Ray raySide = new Ray(cam.transform.position, cam.transform.right * -Input.GetAxisRaw("Peek"));
      Debug.DrawRay(cam.transform.position, cam.transform.right * -Input.GetAxisRaw("Peek"));
      RaycastHit rayHitSide;





      if (rotation.x > 0)
      {
        VerticalCameraMult = -(rotation.x * 3.57f / 100) + 1;
      }
      else
      {
        VerticalCameraMult = (rotation.x * 3.57f / 100) + 1;
      }



      if (groundedPlayer == false || head.isColliding)
      {
        rayMult = 0f;
      }

      else if (Physics.Raycast(raySide, out rayHitSide, 6))
      {

        rayMult = Mathf.Clamp01(rayHitSide.distance);


      }

      else
      {





        rayMult = 1f;
      }

    }

    float p = Input.GetAxisRaw("Peek");
    Quaternion newRot = cameraPivot.transform.localRotation;



    newRot.eulerAngles = new Vector3(cameraPivot.transform.localRotation.x, cameraPivot.transform.localRotation.y, peekAmount * p * rayMult * VerticalCameraMult);


    cameraPivot.transform.localRotation = Quaternion.Slerp(cameraPivot.transform.localRotation, newRot, Time.deltaTime * peekSpeed);

  }

  public void Sneak()
  {
    float newHeight ;

    if (groundedPlayer)
    {
      if (Input.GetButton("Sneak"))
      {
        isSneaking = true;
        newHeight = baseheight.y - sneakHeight;
        sneakYvec = Mathf.SmoothStep(cam.transform.localPosition.y, newHeight, 0.3f);
        currentSneakMult = sneakMult;
        currentCrouchJumpMult = crouchJumpMult;
      }
      else if (!Input.GetButton("Sneak"))
      {
        isSneaking = false;
        newHeight = baseheight.y;
        sneakYvec = Mathf.SmoothStep(cam.transform.localPosition.y, newHeight, 0.3f);
        currentSneakMult = 1f;
        currentCrouchJumpMult = 1f;
      }



    }
    cam.transform.localPosition = new Vector3(cam.transform.localPosition.x, sneakYvec, cam.transform.localPosition.z);
  }
  private void OnControllerColliderHit(ControllerColliderHit hit)
  {
    Rigidbody rb;
    if (hit.rigidbody)
    {
      rb = hit.rigidbody;
      if (!rb.isKinematic)
      {
        rb.AddForce (player.velocity.normalized * pushForce);
      }
    }
  }
}
