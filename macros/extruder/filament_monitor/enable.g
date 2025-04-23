; Description: 	
;	Reset the accumulated value in the filament monitor sensor.
; Input Parameters:
;	- T (optional): Tool 0 or 1 where the filament monitor is connected. If it
;					is not present, the filament monitor will be enabled in
;					all the available extruders.
; Example:
;	M98 P"/macros/extruder/filament_monitor/enable.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/filament_monitor/enable.g"
M118 S{"[SENSOR] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Input parameters ------------------------------------------------------------
var ENABLE_T0 = (!exists(param.T) || (param.T == 0) )
var ENABLE_T1 = (!exists(param.T) || (param.T == 1) )

; Checking if we need to enable T0 --------------------------------------------

if( var.ENABLE_T0 )
	M98 P"/macros/boards/get_index_in_om.g" A81
	if(global.boardIndexInOM != null) 
		M118 S{"[SENSOR] The filament monitor sensor was enabled for T0"}
		M591 D{tools[0].extruders[0]} S1
	
if( var.ENABLE_T1 )
	M98 P"/macros/boards/get_index_in_om.g" A82
	if(global.boardIndexInOM != null) 
		M118 S{"[SENSOR] The filament monitor sensor was enabled for T1"}
		M591 D{tools[1].extruders[0]} S1

; -----------------------------------------------------------------------------
M118 S{"[SENSOR] Done "^var.CURRENT_FILE}
M99 ; Proper exit