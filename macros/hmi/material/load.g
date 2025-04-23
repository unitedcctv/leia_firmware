; Description:
;   HMI command macro to load the filament in the selected tool or select a tool if specified. Does not run any tool change macro files (P0)
;	
; Input Parameters:
;   - T : tool index
; Example:
;	M98 P"/macros/hmi/material/load.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/material/load.g"
M118 S{"[load.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; select tool
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/material/load.g"} F{var.CURRENT_FILE} E87020
if (exists(param.T))
	M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E87021
	if(param.T != state.currentTool)
		T{param.T} P0
else
	M98 P"/macros/assert/abort_if.g" R{state.currentTool == -1} Y{"No tool selected and no param T provided"}    F{var.CURRENT_FILE} E87022

; Check that the extruder is not too cold
M98 P"/macros/assert/abort_if.g" R{tools[state.currentTool].active[0] < heat.coldExtrudeTemperature} Y{"No tool selected and no param T provided"}    F{var.CURRENT_FILE} E87023
; calling the load macro
M98 P"/macros/material/load.g" T{param.T}
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"[load.g] Done "^var.CURRENT_FILE}
M99