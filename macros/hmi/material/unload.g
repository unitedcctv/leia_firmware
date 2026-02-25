; Description:
;   HMI command macro to unload the filament in the selected tool or select a tool if specified. Does not run any tool change macro files (P0)
;	
; Input Parameters:
;   - T : tool index
; Example:
;	M98 P"/macros/hmi/material/unload.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/material/unload.g"
M118 S{"[HMI] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; select tool
if (exists(param.T))
	M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E87100
	M98 P"/macros/assert/abort_if.g" R{param.T != 0} Y{"Only T0 supported"} F{var.CURRENT_FILE} E87101
	
if(state.currentTool != 0)
	T0 P0

; Check that the extruder is not too cold
M98 P"/macros/assert/abort_if.g" R{tools[0].active[0] < heat.coldRetractTemperature} Y{"Extruder too cold"}    F{var.CURRENT_FILE} E87102

; Unload Procedure -------------------------------------------------------------
; set relative extrusion mode
M98 P"/macros/report/event.g" Y{"Starting unload T%s"} A{param.T,} F{var.CURRENT_FILE} V87103
M83
; Extruding 20mm with 3mm/s, in mm/min
G1 E{20} F{3*60}
M400
; Retract 71mm with 40mm/s, in mm/min
G1 E{-71} F{40*60}
M400
M98 P"/macros/report/event.g" Y{"Cooling down filament for 30 seconds. Please wait until it has been ejected"} F{var.CURRENT_FILE} V87104
; wait 30 sec
G4 S30
; Retract 38mm with 40mm/s, in mm/min
G1 E{-38} F{40*60}
M400
M98 P"/macros/report/event.g" Y{"Done unloading T%s. You can remove the filament now"} A{param.T,} F{var.CURRENT_FILE} V87105
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"[HMI] Done "^var.CURRENT_FILE}
M99 ; Proper exit

