; Description: 	
;	Frees the tool.
;	To be called from tfree0.g or tfree1.g when using generic extruders.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
; Ïnput Parameters:
;	- T: Tool number (0 or 1) to free.
; Example:
;	M98 P"/macros/extruder/tfree.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/tfree.g"
M118 S{"[tfree.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
if !exists(param.T)
	M118 S{"[tfree.g] param.T does not exist"}
	M99
M400
if param.T == null || param.T >= 2 || param.T < 0
	M118 S{"[tfree.g] Unexpected value: param.T = " ^ param.T}
	M99
M400

; Definitions -----------------------------------------------------------------
var ACTIVE_TEMP = tools[param.T].active[0]

; Set temperature back because duet switches to standby temperature after tool change
M568 P{param.T} S{var.ACTIVE_TEMP} R{var.ACTIVE_TEMP} A2

; Set the LED -----------------------------------------------------------------
; LED strip feature removed

; -----------------------------------------------------------------------------
M118 S{"[tfree.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit