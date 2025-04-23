; Description: 	
; To test the flowrate in extruder 1 with 300mm in 3mm/s
;	- T: Tool 0 or 1 to configure
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fat/flowrate/test_t1.g"
M118 S{"[TOOL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

;checking the files------------------------------------------------------------
; Reseting the value  ---------------------------------------------------------
T1
M98 P"/macros/extruder/filament_monitor/reset_accumulated.g" T1
M118 S{"[TOOL] Reset the value of fila_accu_t1"}
;Setting the current extruder temperature to be 190 and wait-------------------
M109 S190
;Extrude 300 mm of filament in 3mm/s speed-------------------------------------
G1 E300 F180
;wait until the moves are finish-----------------------------------------------
M400
M118 S{"[TOOL] Done extruding 300mm of filament in 3mm/s speed"}

; -----------------------------------------------------------------------------
M118 S{"[TOOL] Done "^var.CURRENT_FILE}
M99
