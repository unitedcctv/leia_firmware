; Description: 	
;	This will call preload fhx T1
; Example:
;	M98 P"/macros/fhx/control/trigger/preload/roll1_t0.g" 
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/trigger/preload/roll0_t1.g"
M118 S{"[roll0_t1.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; loading filament ------------------------------------------------------------
if(state.status == "processing" )
    M98 P"/macros/fhx/material/load/preload_printing.g" T1 S0
else
    M98 P"/macros/fhx/material/load/automatic_preload.g" T1 S0 ; preloading filament T0
M598
; -----------------------------------------------------------------------------
M118 S{"[roll0_t1.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit