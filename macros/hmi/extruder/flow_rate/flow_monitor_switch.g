; Description: 	
;	This will enable or disable the filament flow monitoring sensor.
;		it is a toggle macro.
; ; Example:
;	M98 P"/macros/hmi/extruder/flow_rate/flow_monitor_switch.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/flow_rate/flow_monitor_switch.g"
M118 S{"[flow_monitor_switch.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
;creating the global variables----------------------------------------------
if(!exists(global.flowMonitoringActive))
	M98 P"/macros/report/warning.g" Y"Flow monitoring sensor doesn't exist" F{var.CURRENT_FILE} W84320
	M118 S{"[flow_monitor_switch.g]Done "^var.CURRENT_FILE}
	M99 ; Not an abort as we may be printing
set global.flowMonitoringActive = !global.flowMonitoringActive ;toggling the value
; checking the status of the filament monitor------------------------------------------
while (iterations < #tools)
	if(tools[iterations] == null)
		continue
	if(global.flowMonitoringActive)
		M591 D{tools[iterations].extruders[0]} S1
		M98 P"/macros/report/event.g" Y{"Flow monitoring enabled for the tool %s"} A{iterations,} F{var.CURRENT_FILE} V84320
	else
		M591 D{tools[iterations].extruders[0]} S0
		M98 P"/macros/report/event.g" Y{"Flow monitoring disabled for the tool %s"} A{iterations,} F{var.CURRENT_FILE} V84321
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -------------------------------------------------------------------------------------------
M118 S{"[flow_monitor_switch.g]Done "^var.CURRENT_FILE}
M99
