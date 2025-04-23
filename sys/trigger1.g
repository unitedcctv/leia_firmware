
; Description: 	
;	Nothing is done, except pausing the print.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/trigger1.g"
M118 S{"[trigger1.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

;------------------------------------------------------------------------------
M118 S{"[trigger1.g] Done "^var.CURRENT_FILE}
M25
M99 ; Proper exit 