; Description: 	
;	Pre selection tool script.
;	To be called from tpre0.g or tpre1.g when using generic extruders.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
; Ïnput Parameters:
;	- T: Tool number (0 or 1) to execute the post selection.
; Example:
;	M98 P"/macros/extruder/tpre.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/tpre.g"
M118 S{"[tpre.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------

if !exists(param.T)
	M118 S{"[tpre.g] param.T does not exist"}
	M99
M400
if param.T == null || param.T >= 2 || param.T < 0
	M118 S{"[tpre.g] Unexpected value: param.T = " ^ param.T}
	M99
M400

; Definitions -----------------------------------------------------------------
var PRINTING = (state.thisInput = 2) && exists(global.homingDone) && global.homingDone

if var.PRINTING
	if !exists(global.lastPrintingTool) ; might not exist if we're resuming from power outage
		global lastPrintingTool = param.T
	else
		set global.lastPrintingTool = param.T
; -----------------------------------------------------------------------------
M118 S{"[tpre.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit