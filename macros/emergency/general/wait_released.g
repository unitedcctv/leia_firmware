; Description:
;	- Checking for the emergency by checking whether the 48 V is available 
;	  or not.
;   - If trhe 48V is available(=1) that means the emergency is not trigerred.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/emergency/general/wait_released.g"
M118 S{"[EMERGENCY] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var TIMEOUT_WAITING = 60	; [sec] Max. time waiting for the emergency signal.

; Checking and waiting -------------------------------------------------------
if(exists(global.emergencyGeneralIsTriggered))
	if(global.emergencyGeneralIsTriggered)
		M98 P"/macros/report/warning.g" Y"48V is not detected" F{var.CURRENT_FILE} W56100
		var TIMEOUT = {state.time + var.TIMEOUT_WAITING}
		while((global.emergencyGeneralIsTriggered == true) && (var.TIMEOUT > state.time))
			G4 S1
		if(var.TIMEOUT <= state.time)
			M98 P"/macros/assert/abort.g" Y{"General emergency not released on time."}  F{var.CURRENT_FILE} E56100
	M118 S{"[EMERGENCY] General emergency is not triggered, ready for testing the voltage"}
else
	M98 P"/macros/report/warning.g" Y"General emergency variable not available" F{var.CURRENT_FILE} W56101

; -----------------------------------------------------------------------------
M118 S{"[EMERGENCY] Done "^var.CURRENT_FILE}
M99