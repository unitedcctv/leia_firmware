; Description: 	
;	Reset the accumulated value in the filament monitor sensor.
; Input Parameters:
;	- T (optional): Tool 0 or 1 where the filament monitor is connected. If it
;					is not present, the filament monitor will be disabled in
;					all the available extruders.
; Example:
;	M98 P"/macros/extruder/filament_monitor/disable.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/filament_monitor/disable.g"
M118 S{"[SENSOR] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Input parameters ------------------------------------------------------------
var DISABLE_T0 = (!exists(param.T) || (param.T == 0) )
var DISABLE_T1 = (!exists(param.T) || (param.T == 1) )

; Checking if we need to disable T0 -------------------------------------------

if( var.DISABLE_T0 )
	M98 P"/macros/boards/get_index_in_om.g" A81
	if(global.boardIndexInOM != null) 
		M118 S{"[SENSOR] The filament monitor sensor was disabled for T0"}
		M591 D{tools[0].extruders[0]} S0
	
if( var.DISABLE_T1 )
	; T1 removed - single extruder setup

; -----------------------------------------------------------------------------
M118 S{"[SENSOR] Done "^var.CURRENT_FILE}
M99 ; Proper exit