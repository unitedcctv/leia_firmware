; Description: 	
;	   In this, we will check that:
;		   - check for the door to be closed
;		   - check whether the emergency is trigerred or not
;		   - check for the voltage
;		   - Setting the CBC temperature is set 0
;		   - clock the doors
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/printing/get_ready.g"
M118 S{"[get_ready.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking if files exists
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/general/wait_released.g"} 	F{var.CURRENT_FILE} E64000
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/voltages/wait.g"} F{var.CURRENT_FILE} E64002
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/lock.g"} 			F{var.CURRENT_FILE} E64003
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/cbc/set_default_if_off.g"} F{var.CURRENT_FILE} E64004

; Getting the machine prepared to print ---------------------------------------
;check whether the emergency is trigerred or not
M98 P"/macros/emergency/general/wait_released.g"
;Check voltages before the print
M98 P"/macros/sensors/voltages/wait.g"
;Lock the door before Printing
M98 P"/macros/doors/lock.g"
; Set the CBC to 0ºC
;M98 P"/macros/cbc/set_default_if_off.g"

; -----------------------------------------------------------------------------
M118 S{"[get_ready.g] Done "^var.CURRENT_FILE}
M99