; Description: 	
;	This will call mixratio if oof is triggered  T1 Roll0
; Example:
;	M98 P"/macros/fhx/control/trigger/mixratio/roll0_t1.g" 
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/trigger/mixratio/roll0_t1.g"
M118 S{"[CALL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; loading filament ------------------------------------------------------------
M98 P"/macros/fhx/control/trigger/mixratio_status.g" T1 S0 ; changing mix ratio T0
M598

; -----------------------------------------------------------------------------
M118 S{"[CALL] Done "^var.CURRENT_FILE}
M99 ; Proper exit
