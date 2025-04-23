; Description: 	
;	Macro to set the Z baby stepping
;       Input parameter:
;          S : Amount of Z baby step in mm
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/axes/baby_stepping.g"
M118 S{"[baby_stepping.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/axes/babystep_tool.g"} F{var.CURRENT_FILE} E80001
; Check that S is present and not null
; Check param.S file exists
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}    Y{"Missing the parameter S with the amount of baby step"}    F{var.CURRENT_FILE} E80002
M98 P"/macros/assert/abort_if_null.g" 	R{param.S} Y{"The parameter S with the baby step amount is null"} F{var.CURRENT_FILE} E80003
M98 P"/macros/assert/abort_if.g" R{(state.currentTool == -1)} 	Y{"No tool selected"} 			F{var.CURRENT_FILE} E80004
; Moving ----------------------------------------------------------------------
M98 P{"/macros/axes/babystep_tool.g"} S{param.S}
; -----------------------------------------------------------------------------
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[baby_stepping.g] Done "^var.CURRENT_FILE}
M99