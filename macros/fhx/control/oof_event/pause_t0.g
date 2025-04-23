; Description: 	
;	This will call pause macro for T0
; Example:
;	M98 P"/macros/fhx/control/oof_event/pause_t0.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/oof_event/pause_t0.g"
M118 S{"[OOF] Starting " ^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

M98 P"/macros/fhx/control/oof_event/pause.g" T0

; -----------------------------------------------------------------------------
M118 S{"[OOF] Done " ^var.CURRENT_FILE}
M99 ; Proper exit


