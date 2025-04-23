; Description:
;	We will check the different emergency signals (48V, emergency, ...) and 
;	return true in global.machineReadyToOperate if there is no emergency 
;	signal, otherwise false.
; Output parameters:
;	- global.machineReadyToOperate: True if the machine can operate normally, 
;		otherwise false.
; Example:
;	M98 P"/macros/emergency/is_ready_to_operate.g"
; 	if(global.machineReadyToOperate)
;		G28
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99

var CURRENT_FILE = "/macros/emergency/is_ready_to_operate.g"
M118 S{"[EMERGENCY] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Preparing the return value with the default value
if(!exists(global.machineReadyToOperate))
	global machineReadyToOperate = false
else 
	set global.machineReadyToOperate = false

; Check that the door is closed -----------------------------------------------
if(exists(global.doorIsLocked))
	M98 P"/macros/assert/abort_if.g" R{!global.doorIsLocked}  Y{"The door is open"} F{var.CURRENT_FILE} E56001

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_EMERGENCY)}  Y{"Missing module EMERGENCY"} F{var.CURRENT_FILE} E56002

set global.machineReadyToOperate = true ;
if(exists(global.emergencyGeneralIsTriggered))
	if(global.emergencyGeneralIsTriggered)
		set global.machineReadyToOperate = false
if(exists(global.emergencyDoorIsTriggered))
	if(global.emergencyDoorIsTriggered)
		set global.machineReadyToOperate = false

; -----------------------------------------------------------------------------
M118 S{"[EMERGENCY] Done "^var.CURRENT_FILE}
M99