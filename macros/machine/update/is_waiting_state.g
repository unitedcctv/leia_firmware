; Description: 		
;	Macro to abort the config if the machine is waiting for an update.
; Example:
;	M98 P"/macros/machine/update/is_waiting_state.g"
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/update/is_waiting_state.g"
M118 S{"[UPDATE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var UPDATE_READY_FILE = "/sys/machines/update_ready.g"

; Check for the file ----------------------------------------------------------
if(fileexists(var.UPDATE_READY_FILE))
	set global.hmiStateDetail = "board_update_needed"	
	M98 P"/macros/report/event.g" Y{"Machine ready to be updated"}  F{var.CURRENT_FILE} V62310
	M98 P"/macros/assert/abort.g" Y{"Machine ready to be updated"}  F{var.CURRENT_FILE} E62310

; -----------------------------------------------------------------------------
M118 S{"[UPDATE] Done "^var.CURRENT_FILE}
M99 ; Proper exit
