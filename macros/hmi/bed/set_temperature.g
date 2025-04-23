; Description: 	
;	Macro to set the BED temperature
; Input parameter:
;	- T :  Active/Target temperature
; Example:
; 	M98 P"/macros/hmi/bed/set_temperature.g" T60
; Todo: 
;	- When doors open, set max temperature to safe temp limit (e.g. BED_WARNING_TEMP) only
;-----------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/bed/set_temperature.g"
M118 S{"[set_temperature.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions -------------------------------------------------------------------
var BED_MAX_TEMP = heat.heaters[heat.bedHeaters[0]].max ; [dC]
var BED_MIN_TEMP = 0 		; [dC] Min value before turning the bed off
var BED_OFF_TEMP = -273.1 	; [dC] Value to use when the bed is off

; Checking for files first-------------------------------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(global.MODULE_BED)} 	Y{"Missing required module BED"} F{var.CURRENT_FILE} E81100
M98 P"/macros/assert/abort_if.g" 		R{!exists(global.bedTempLastSetTime)} 	Y{"Missing required module BED"} F{var.CURRENT_FILE} E81107
; Check that param.T is present and not null
; Check param.T file exists
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.T)} 			Y{"Missing the parameter T with the target temperature"} F{var.CURRENT_FILE} E81101
M98 P"/macros/assert/abort_if_null.g" 	R{param.T} 						Y{"The parameter T with the target temperature is null"} F{var.CURRENT_FILE} E81103
M98 P"/macros/assert/abort_if.g" 		R{(param.T>var.BED_MAX_TEMP)}  	Y{"The parameter T with the target temperature is greater than the allowed max temperature"} F{var.CURRENT_FILE} E81102

; Set the temperature -----------------------------------------------------------
var BED_TARGET_TEMP = param.T
if (var.BED_TARGET_TEMP <= var.BED_MIN_TEMP)
	; need to set to 0 first, otherwise the display temperature will not be updated
	M140 S{var.BED_MIN_TEMP} R{var.BED_MIN_TEMP}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature to var.MIN_TEMP" F{var.CURRENT_FILE} E81104

	M140 S{var.BED_OFF_TEMP}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature to var.OFF_TEMP" F{var.CURRENT_FILE} E81105

elif (var.BED_TARGET_TEMP < global.BED_HAZARD_TEMP)
	M140 S{var.BED_TARGET_TEMP} R{var.BED_TARGET_TEMP}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature" F{var.CURRENT_FILE} E81106
	set global.bedTempLastSetTime = state.upTime

elif (var.BED_TARGET_TEMP >= global.BED_HAZARD_TEMP)
	if (!global.doorIsLocked)
		M98 P"/macros/doors/lock.g"
	
	M400 ; alternatively try M598

	M140 S{var.BED_TARGET_TEMP} R{var.BED_TARGET_TEMP}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the bed temperature" F{var.CURRENT_FILE} E81108
	set global.bedTempLastSetTime = state.upTime

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}		
; -------------------------------------------------------------------------------
M118 S{"[set_temperature.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit