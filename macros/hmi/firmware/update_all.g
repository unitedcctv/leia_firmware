; Description: 	
;   This is a HMI command macro to update the firmware
;   To make it readable for the MQTT users its better to have macros to call the M-codes
;       - this macro is used to call the /macros/machine/update/set_waiting_state.g 
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/firmware/update_all.g"
M118 S{"[update_all.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
;--------------------------------------------------------------------------------------------------------
; set HMI State
set global.hmiStateDetail = "board_update_running"

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/update/clear_waiting_state.g"} F{var.CURRENT_FILE} E85400
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/firmware/update_all.g"} F{var.CURRENT_FILE} E85401
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/bootloader/update_all.g"} F{var.CURRENT_FILE} E85402
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/machine/configuration/update.g"} F{var.CURRENT_FILE} E85403

; Clear the update state---------------------------------------------------------
M98 P"/macros/machine/update/clear_waiting_state.g"
; Updating the bootloader--------------------------------------------------------
M118 S{"Updating the bootloader"}
M98 P"/macros/machine/bootloader/update_all.g" R0
; Updating the configuration-----------------------------------------------------
M118 S{"Updating the configuration"}
M98 P"/macros/machine/configuration/update.g"
; Updating the firmware----------------------------------------------------------
M118 S{"Updating the firmware"}
M98 P"/macros/machine/firmware/update_all.g" R0
;---------------------------------------------------------------------------------------------------------
M118 S{"Machine will restart now to update everything"}
G4 S3

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------
M118 S{"[update_all.g] Done "^var.CURRENT_FILE}
M999	;Proper file exit