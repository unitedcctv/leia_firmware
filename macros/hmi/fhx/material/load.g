; Description: 	
;	This will call load fhx for selected roll
; Example:
;	M98 P"/macros/hmi/fhx/material/load.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/fhx/material/load.g"
M118 S{"[CALL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/material/load/feed_spool.g"} F{var.CURRENT_FILE} E87003

; Checking global variables and input parameters ------------------------------
; select tool
if (exists(param.T))
	M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E87004
	if(param.T != state.currentTool)
		T{param.T} P0
else
	M98 P"/macros/assert/abort_if.g" R{state.currentTool == -1} Y{"No tool selected and no param T provided"}    F{var.CURRENT_FILE} E87005
	M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)} Y{"Spool Index param.S=%s is outside range of available spools"} A{param.S,} F{var.CURRENT_FILE} E87006
M400
M598

; loading filament ------------------------------------------------------------
M98 P"/macros/fhx/material/load/feed_spool.g" T{param.T} S{param.S}
M598

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[CALL] Done "^var.CURRENT_FILE}
M99 ; Proper exit