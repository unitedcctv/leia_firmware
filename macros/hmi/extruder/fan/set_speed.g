; Description: 	
;	This macro is used to set the speed of the tool 0 fan
;   the value should be in the range 0 to 1
; Input Parameters:
;	- S: Speed in 0 to 1.
;	- T: Tools 0 or 1
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/fan/set_speed.g"
M118 S{"[set_speed.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(param.T)}     	Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E84023
M98 P"/macros/assert/abort_if_null.g" 	R{param.T}              	Y{"Tool index param.T is null"} 	F{var.CURRENT_FILE} E84024
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E84025
M98 P"/macros/assert/abort_if_null.g" 	R{param.S}              	Y{"Fan speed param L is null"} F{var.CURRENT_FILE} E84020
M98 P"/macros/assert/abort_if.g" 		R{param.S < 0|| param.S >1}				Y{"Entered fan speed  is out of range (0 to 1)"} F{var.CURRENT_FILE} E84021

; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/fan/set_speed.g"} F{var.CURRENT_FILE} E84022
; Setting the tool fan speed
M98 P"/macros/extruder/fan/set_speed.g" T{param.T} S{param.S}

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------------------
M118 S{"[set_speed.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit