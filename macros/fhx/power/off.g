; Description: 	
;	This will turn off the power of the FHX.
; Example:
;	M98 P"/macros/fhx/power/off.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/power/off.g"
M118 S{"[FHX]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/power/set.g"} F{var.CURRENT_FILE} E71146

; Turn the power OFF ------------------------------------------------------------
M98 P"/macros/fhx/power/set.g" S0 
M118 S{"[FHX] Power is OFF"}

; -----------------------------------------------------------------------------
M118 S{"[FHX] Done "^var.CURRENT_FILE}
M99 ; Proper exit
