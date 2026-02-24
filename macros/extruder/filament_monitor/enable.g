; Description: 	
;	Reset the accumulated value in the filament monitor sensor.
; Input Parameters:
;	- T (optional): Tool index (only T0 supported - single extruder)
; Example:
;	M98 P"/macros/extruder/filament_monitor/enable.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/filament_monitor/enable.g"
M118 S{"[SENSOR] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Input parameters ------------------------------------------------------------
if exists(param.T)
	M98 P"/macros/assert/abort_if.g" R{param.T != 0} Y{"Only T0 supported - single extruder setup"} F{var.CURRENT_FILE} E57670

; Enable filament monitor for T0 ---------------------------------------------
M98 P"/macros/boards/get_index_in_om.g" A81
if(global.boardIndexInOM != null) 
	M118 S{"[SENSOR] The filament monitor sensor was enabled for T0"}
	M591 D{tools[0].extruders[0]} S1

; -----------------------------------------------------------------------------
M118 S{"[SENSOR] Done "^var.CURRENT_FILE}
M99 ; Proper exit