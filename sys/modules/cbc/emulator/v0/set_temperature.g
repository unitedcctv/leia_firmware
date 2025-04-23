; Description: 	As in the emulator, we can create a proper heater, the control does nothing.
;	 Input Parameters:
;		  - T (optional): Target Temperature [ºC] to set in the CBC. If 0, the fans are 
;						 heaters are off.
;		  - D (optional): Max. Difference between the target temperature [ºC] and the 
;						 current one.
;	 NOTE: This file should be linked to /macros/cbc/set_temperature.g
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/cbc/emulator/v0/set_temperature.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_CBC)}  Y{"Missing CBC configuration "} F{var.CURRENT_FILE} E11150
M98 P"/macros/assert/abort_if.g" R{!exists(global.CBC_HEATER)}  Y{"Missing required global CBC_HEATER"} F{var.CURRENT_FILE} E11151

if(!exists(global.cbcTargetTemperature))
	global cbcTargetTemperature 	= 0.0  ; [ºC] Global variable used to set the target temperature

if ( !exists(param.T) || (exists(param.T) && param.T == null) || (exists(param.T) && param.T != null && param.T <= 0) )
	M141 H{global.CBC_HEATER} S-273.1
	set global.cbcTargetTemperature = 0.0 ; Off
else
	; Define the delta Temperature:
	; 	Tmax = param.T + deltaTemp
	; 	Tmin = param.T - deltaTemp
	var deltaTemp = 0.0 ; [ºC]
	if( exists(param.D) && param.D != null && param.D > 0 )
		set var.deltaTemp = {param.D}
	M141 H{global.CBC_HEATER} S{ param.T + (var.deltaTemp/2) }
	set global.cbcTargetTemperature = { param.T + (var.deltaTemp/2) }
