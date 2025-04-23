; Description: 	
;	Nothing is done!
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/sleep.g"
M118 S{"[SLEEP] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; -----------------------------------------------------------------------------
M118 S{"[SLEEP] Done "^var.CURRENT_FILE}
M99 ; Proper exit 