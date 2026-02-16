; Description:
;	Apply a Z babystep offset to adjust nozzle height.
; Input parameters:
;	- S: [mm] Offset in mm to move.
;	- T: (optional) Tool number.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/axes/babystep_tool.g"
M118 S{"[babystep_tool.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)} 			Y{"Missing input parameter S"} 	F{var.CURRENT_FILE} E51105
M98 P"/macros/assert/abort_if_null.g" R{param.S} 				Y{"Input parameter S is null"}	F{var.CURRENT_FILE} E51107

var TOOL = exists(param.T) ? param.T : state.currentTool
var STEP_SIZE = param.S

; Apply Z babystep -------------------------------------------------------------
M290 R0 S{var.STEP_SIZE}
M400

; -----------------------------------------------------------------------------
M118 S{"[babystep_tool.g] Done babystepping Z "^var.STEP_SIZE^"mm"}
M99