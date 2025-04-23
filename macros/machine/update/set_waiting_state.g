; Description: 		
;	(!) This will disable the configuration after the machine is restarted.The
;		machine will be waiting for an update (FW or configuration).
;	We will create a file that is used to make sure the configuration is not 
;	loaded. Once it is restarted the machine will be ready to be updated. 
;	It is not recommended to upload files if the machine is not the
;	"waiting_update" state, so without calling this macro before.
; Example:
;	M98 P"/macros/machine/update/set_waiting_state.g"
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/machine/update/set_waiting_state.g"
M118 S{"[UPDATE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var UPDATE_READY_FILE = "/sys/machines/update_ready.g"

; Create the update
echo >{var.UPDATE_READY_FILE}  {"; Nothing to be done"}
echo >>{var.UPDATE_READY_FILE} {"M99"}

M98 P"/macros/report/event.g" Y{"The machine will be in 'waiting_update' after reset"}  F{var.CURRENT_FILE} V62300

; -----------------------------------------------------------------------------
M118 S{"[UPDATE] Done "^var.CURRENT_FILE}
M99 ; Proper exit
