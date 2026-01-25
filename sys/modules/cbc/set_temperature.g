; Description: 	We can create a proper heater, the control does nothing.
;	 Input Parameters:
;		  - T (optional): Target Temperature [ºC] to set in the CBC. If 0, the fans are 
;						 heaters are off.
;	 NOTE: This file should be linked to /macros/cbc/set_temperature.g
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/cbc/set_temperature.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_CBC)}  Y{"Missing CBC configuration "} F{var.CURRENT_FILE} E11194

; Creating global variables with default values if they are not there. 
if(!exists(global.cbcTargetTemperature))
	global cbcTargetTemperature 	= 0.0  		; [ºC] Global variable used to set the target temperature

if ( exists(param.T) && param.T != null && param.T > 0 )
	M98 P"/macros/assert/abort_if.g" R{param.T > global.CBC_MAX_TEMP}  Y{"CBC Temperature limit is  %s°C"} A{global.CBC_MAX_TEMP,} F{var.CURRENT_FILE} E11195
	set global.cbcTargetTemperature = param.T;
	set global.cbcPIDPrevError	= 0				; Reset previous CBC PID error value to 0 
	set global.cbcPIDPrevErrorInt	= 0			; Reset previous CBC PID integral of error value to 0
else
	set global.cbcTargetTemperature = 0.0;

M99	;Proper exit 