; Description: 	
;	Reset the accumulated value in the filament monitor sensor.
; Input Parameters:
;	- T: Tool 0 or 1 where the filament monitor is connected
; Example:
;	M98 P"/macros/extruder/filament_monitor/reset_accumulated.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/filament_monitor/reset_accumulated.g"
M118 S{"[SENSOR] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/find_by_name.g"} 				F{var.CURRENT_FILE} E57600
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E57601
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E57602
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E57603

; Exist if we are in an emulator ----------------------------------------------
if (network.hostname == "emulator")	
	M118 S{"[SENSOR] Reset accumulated not supported in emulator"}
	M99

; Finding the sensor ----------------------------------------------------------
if(!exists(global.sensorIndex))
	global sensorIndex = null
	M400	; Making sure the global is available
	G4 S0.1
M98 P"/macros/sensors/find_by_name.g" N{"fila_accu_t"^param.T^"[mm]"}
M400
G4 S1
; Checking the result
M98 P"/macros/assert/abort_if.g" R{!exists(global.sensorIndex)}  Y{"Missing return value global.sensorIndex"} F{var.CURRENT_FILE} E57604
M98 P"/macros/assert/abort_if_null.g" R{global.sensorIndex}  	 Y{"Accumulated sensor in filament monitor not found"} F{var.CURRENT_FILE} E57605

; Reseting the value  ---------------------------------------------------------
M308 S{global.sensorIndex} ; Calling the sensor does the reset!
M400
G4 S2 ; Small delay before moving on

M118 S{"[SENSOR] Reseted the value of fila_accu_t"^param.T}

; -----------------------------------------------------------------------------
M118 S{"[SENSOR] Done "^var.CURRENT_FILE^"for T"^param.T}
M99 ; Exit