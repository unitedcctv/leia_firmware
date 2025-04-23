; Description: 	
;	Script to call before the selection of the tool 1.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/tpre1.g"
M118 S{"[tpre1.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var TOOL = 1			; Related tool to this file

; Operation -------------------------------------------------------------------
M98 P"/macros/extruder/tpre.g" T{var.TOOL}

; -----------------------------------------------------------------------------
M118 S{"[tpre1.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit