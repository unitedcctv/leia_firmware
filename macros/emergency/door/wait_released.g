; Description:
;	- Wait until the door emergency is released.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/emergency/door/wait_released.g"
M118 S{"[EMERGENCY] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var TIMEOUT_WAITING = 60	; [sec] Max. time waiting for the emergency signal.

; Checking and waiting -------------------------------------------------------
if(exists(global.emergencyDoorIsTriggered))
	if(global.emergencyDoorIsTriggered)
		M98 P"/macros/report/warning.g" Y"Door is not detected" F{var.CURRENT_FILE} W56110
		var TIMEOUT = {state.time + var.TIMEOUT_WAITING}
		while( (global.emergencyDoorIsTriggered == true) && (var.TIMEOUT > state.time))
			G4 S1
		if(var.TIMEOUT <= state.time)
			M98 P"/macros/assert/abort.g" Y{"Door emergency not released on time."}  F{var.CURRENT_FILE} E56110
	M118 S{"[EMERGENCY] Door emergency is not triggered, ready for testing the voltage"}
else
	M98 P"/macros/report/warning.g" Y"Door emergency variable not available" F{var.CURRENT_FILE} W56111

; -----------------------------------------------------------------------------
M118 S{"[EMERGENCY] Done "^var.CURRENT_FILE}
M99