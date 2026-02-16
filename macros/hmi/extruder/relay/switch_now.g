; Description: 	
;   This macro will 
;       - select the other extruder 
;       - and resume the print
;   when the current printing tool triggers oof and continue the printing.
;--------------------------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;----------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/relay/switch_now.g"
M118 S{"[switch_now.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; checking for the variables
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/relay/switch_now.g"} 	F{var.CURRENT_FILE} E84030
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/relay/prerequisite.g"} 	F{var.CURRENT_FILE} E84031
; Calling the switch now---------------------------------------------------------------------------
M98 P"/macros/extruder/relay/prerequisite.g"
M400
M98 P"/macros/extruder/relay/switch_now.g"
M400

M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"[switch_now.g] Done "^var.CURRENT_FILE}
M99
