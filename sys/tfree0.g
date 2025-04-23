; Description: 	
;	Frees the tool 0.
;   We cannot abort in tool change macros as per doc https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/tfree0.g"
M118 S{"[tfree0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -----------------------------------------------------------------
var TOOL = 0			; Related tool to this file

; Operation -------------------------------------------------------------------
M98 P"/macros/extruder/tfree.g" T{var.TOOL}

; -----------------------------------------------------------------------------
M118 S{"[tfree0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit