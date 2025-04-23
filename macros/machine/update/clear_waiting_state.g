; Description: 		
;	We will remove the file that is used to make sure the configuration is not 
;	loaded. This macro should be called once the FW or/and Configuration is 
;	updated.
; Example:
;	M98 P"/macros/machine/update/clear_waiting_state.g"
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/update/clear_waiting_state.g"
M118 S{"[UPDATE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var UPDATE_READY_FILE = "/sys/machines/update_ready.g"

; Removing the file ----------------------------------------------------------.
M472 P{var.UPDATE_READY_FILE} 

M98 P"/macros/report/event.g" Y{"The machine will be load the configuration after reset"}  F{var.CURRENT_FILE} V62301

; -----------------------------------------------------------------------------
M118 S{"[UPDATE] Done "^var.CURRENT_FILE}
M99 ; Proper exit
