; Description: 	
;	Macro to set the CBC temperature
; Input parameter:
;   -T : Target Temperature
; Example:
; 	M98 P"/macros/hmi/cbc/set_temperature.g" T60
;---------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/cbc/set_temperature.g"
M118 S{"[set_temperature.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/cbc/set_temperature.g"} F{var.CURRENT_FILE} E82000
M98 P"/macros/assert/abort_if.g"    R{!exists(global.MODULE_CBC)} 				Y{"Missing required module CBC"} 			  		F{var.CURRENT_FILE} E82001
M98 P"/macros/assert/abort_if.g"    R{!exists(global.cbcTargetTemperature)} 	Y{"Missing global variable cbcTargetTemperature"} 	F{var.CURRENT_FILE} E82002
M98 P"/macros/assert/abort_if.g"    R{!exists(global.CBC_MAX_TEMP)}             Y{"Missing global variable CBC_MAX_TEMP"} 	F{var.CURRENT_FILE} E82003
M98 P"/macros/assert/abort_if.g"        R{!exists(param.T)}    Y{"Missing the parameter T with the target temperature"}    F{var.CURRENT_FILE} E82004
M98 P"/macros/assert/abort_if_null.g" 	R{param.T}             Y{"The parameter T with the target temperature is null"} F{var.CURRENT_FILE} E82005
M98 P"/macros/assert/abort_if.g"        R{(param.T) > global.CBC_MAX_TEMP }    Y{"param.T is greater than the allowed maximum temperature"}    F{var.CURRENT_FILE} E82006
; If the CBC target temperature is 0 or lower, the CBC is off so we set up the 
; default temperature
M98 P{"/macros/cbc/set_temperature.g"} T{param.T} ;calling the destination file with the target temperature.
if(param.T > 0)
    set global.cbcLastSetTime = state.upTime

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;------------------------------------------------------------------------------------------------------
M118 S{"[set_temperature.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit