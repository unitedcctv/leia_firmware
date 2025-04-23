; Description: 	
;	This will call preload fhx T0
; Example:
;	M98 P"/macros/fhx/control/trigger/preload/roll0_t0.g" 
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/trigger/preload/roll0_t0.g"
M118 S{"[roll0_t0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; loading filament ------------------------------------------------------------
if(state.status == "processing" )
	M98 P"/macros/fhx/material/load/preload_printing.g" T0 S0
else
	M98 P"/macros/fhx/material/load/automatic_preload.g" T0 S0 ; preloading filament T0
M598
; -----------------------------------------------------------------------------
M118 S{"[roll0_t0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
