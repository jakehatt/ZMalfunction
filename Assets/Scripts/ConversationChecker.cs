using AC;
using UnityEngine;

public class ConversationChecker : MonoBehaviour
{   
    [SerializeField] FirstPersonLook firstPersonLook;
    [SerializeField] FirstPersonMovement firstPersonMovement;
    [SerializeField] Jump jump;
    [SerializeField] Crouch crouch;
    

    private bool convoOpen;

    void Update()
    {
        bool isNowConvoOpen = IsConversationOpen();
        
        // Only perform actions if the conversation state has changed
        if (convoOpen != isNowConvoOpen)
        {
            convoOpen = isNowConvoOpen;
            
            if (convoOpen)
            {
                // Pauses game by stopping controls and setting in-game cursor state for AC to handle
                firstPersonLook.enabled = false;
                firstPersonMovement.enabled = false;
                jump.enabled = false;
                crouch.enabled = false;

                
            }
            else
            {
                // Resume controls and restore cursor lock state
                firstPersonLook.enabled = true;
                firstPersonMovement.enabled = true;
                jump.enabled = true;
                crouch.enabled = true;

                
            }
        }
    }

    public bool IsConversationOpen()
    {
        // Check if there's an active conversation in Adventure Creator
        return KickStarter.playerInput.activeConversation != null;
    }
}
