; Description: 	
;	Loads nozzle sizes from permanent variables and sets global.nozzleSizes
; Input Parameters:
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/nozzle/load.g"
M118 S{"[load.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(!exists(global.nozzleSizes))
	global nozzleSizes = {0.6, 0.6}
	M98 P"/macros/variable/load.g" N"global.nozzleSizes"
	; Checking the saved values
	if({global.savedValue != null} && {#global.savedValue == 2})
		M118 S{"[load.g] Loaded nozzle sizes: " ^ global.savedValue}
		set global.nozzleSizes = global.savedValue
	else
		M118 S{"[load.g] No 'global.nozzleSizes' persistent variable found or invalid format, using defaults"}
M400

;--------------------------------------------------------------------------------------------------------
M118 S{"[load.g] Done "^var.CURRENT_FILE}
M99