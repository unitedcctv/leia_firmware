; Description: 	
;	This will enable or disable the filament oof monitoring sensor.
;		it is a toggle macro.
; ; Example:
;	M98 P"/macros/hmi/extruder/oof_monitor_switch.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/oof_monitor_switch.g"
M118 S{"[oof_monitor_switch.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
;creating the global variables----------------------------------------------
if(!exists(global.oofMonitoringActive))
	M98 P"/macros/report/warning.g" Y"OOF monitoring sensor doesn't exist" F{var.CURRENT_FILE} W84322
	M118 S{"[oof_monitor_switch.g]Done "^var.CURRENT_FILE}
	M99 ; Not an abort as we may be printing
set global.oofMonitoringActive = !global.oofMonitoringActive ;toggling the value
; checking the status of the filament monitor------------------------------------------
if(global.oofMonitoringActive)
	M98 P"/macros/report/event.g" Y{"OOF monitoring enabled for the tools"} F{var.CURRENT_FILE} V84322
else
	M98 P"/macros/report/event.g" Y{"OOF monitoring disabled for the tools"} F{var.CURRENT_FILE} V84323
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------------------
M118 S{"[oof_monitor_switch.g]Done "^var.CURRENT_FILE}
M99
