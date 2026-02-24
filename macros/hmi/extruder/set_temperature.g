; Description: 	
;	Macro to set the extruder temperature
;	   Input parameter:
;		   S : target Temperature
;		   T : Tool number; Default : current active tool.
;				if no tools are active then the lowest + tool number
; --------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/set_temperature.g"
M118 S{"[set_temperature.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions--------------------------------------------------------------------
var MIN_TEMP = 0 		; [dC] Min value before turning the tool off
var OFF_TEMP = -273.1 	; [dC] Value to use when the tool is off 
var toolNumber = 0   

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{(!exists(global.exTempLastSetTimes))} Y{"Missing global.exTempLastSetTimes"} F{var.CURRENT_FILE} E84113		
if(!exists(param.T))
	if(state.currentTool != -1)
		set var.toolNumber = state.currentTool
	else
		M98 P"/macros/assert/abort_if.g" R{state.currentTool == -1} Y{"No tool selected and no param T provided"}    F{var.CURRENT_FILE} E84111
else
	M98 P"/macros/assert/abort_if_null.g" 	R{param.T} Y{"The parameter T with the tool number is null"} F{var.CURRENT_FILE} E84102
	M98 P"/macros/assert/abort_if.g" R{((param.T) < 0)} Y{"Invalid tool number"} F{var.CURRENT_FILE} E84103
	M98 P"/macros/assert/abort_if.g" R{(param.T) > (#tools - 1)} Y{"Invalid tool number"} F{var.CURRENT_FILE} E84104
	M98 P"/macros/assert/abort_if.g" R{param.T != 0} Y{"Only T0 supported - single extruder setup"} F{var.CURRENT_FILE} E84101
	M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_EXTRUDER_0)} Y{"Missing required module EXTRUDER 0"} F{var.CURRENT_FILE} E84100
	set var.toolNumber = param.T

var MAX_TOOL_TEMP = heat.heaters[tools[var.toolNumber].heaters[0]].max ; [dC]
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}	Y{"Missing the parameter S with the target temperature"}	F{var.CURRENT_FILE} E84105
M98 P"/macros/assert/abort_if_null.g" 	R{param.S} Y{"The parameter S with the target temperature is null"} F{var.CURRENT_FILE} E84106
M98 P"/macros/assert/abort_if.g" R{(param.S) > (var.MAX_TOOL_TEMP)}	Y{"The parameter S with the target temperature is greater than the allowed maximum temperature"}	F{var.CURRENT_FILE} E84107

; Set the temperature and heater state--------------------------------------------
if (param.S <= var.MIN_TEMP)
	var TARGET_TEMP = var.OFF_TEMP
	M568 P{var.toolNumber} S{var.MIN_TEMP} R{var.MIN_TEMP} A0
	M98 P"/macros/assert/result.g" R{result} Y"Unable to set the extrudert temp to 0 first" F{var.CURRENT_FILE} E84108
	M568 P{var.toolNumber} S{var.TARGET_TEMP} R{var.TARGET_TEMP} A0
	M98 P"/macros/assert/result.g" R{result} Y"Unable to set the target temperature for the extruder in off state" F{var.CURRENT_FILE} E84109
else
	var TARGET_TEMP = param.S
	M568 P{var.toolNumber} S{var.TARGET_TEMP} R{var.TARGET_TEMP} A2
	M98 P"/macros/assert/result.g" R{result} Y"Unable to set the target temperature for the extruder in active state" F{var.CURRENT_FILE} E84110	
	set global.exTempLastSetTimes[var.toolNumber] = state.upTime

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; --------------------------------------------------------------------------------
M118 S{"[set_temperature.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
