; Description: 	
;	This will lock the doors.
; Example:
;	M98 P"/macros/doors/lock.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/doors/lock.g"
M118 S{"[DOORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/control.g"} F{var.CURRENT_FILE} E55100
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_EMERGENCY)} 		Y{"Missing required module EMERGENCY"} 			  F{var.CURRENT_FILE} E55101
M98 P"/macros/assert/abort_if.g" R{!exists(global.emergencyDoorIsTriggered)} 	Y{"Missing global variable emergencyDoorIsTriggered"} F{var.CURRENT_FILE} E55102
M98 P"/macros/assert/abort_if.g" R{!exists(global.doorIsLocked)} 			Y{"Missing global variable doorIsLocked"} 		  F{var.CURRENT_FILE} E55103

; Checking the emergency signal -----------------------------------------------
M98 P"/macros/assert/abort_if.g" R{(global.emergencyDoorIsTriggered)} Y{"The emergency circuit is triggered. The door can't be locked."} F{var.CURRENT_FILE} E55104

; Ensure Drivers were deactivated --------------------------------------------
;M18  ; Turn Motors off

; Closing the door ------------------------------------------------------------
M98 P"/macros/doors/control.g" D1 ; Closing door
M118 S{"[DOORS] Closed"}

; Activate Motors and wait, for driver calibration ----------------------------
;M17  ; Activate motors
;G4 P500  ; Wait for 500ms

; -----------------------------------------------------------------------------
M118 S{"[DOORS] Done "^var.CURRENT_FILE}
M99 ; Proper exit
