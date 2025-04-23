; Description: 	
;	 Turns off the CBC.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/cbc/set_default_if_off.g"

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/cbc/set_temperature.g"} F{var.CURRENT_FILE} E53300
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_CBC)} 				Y{"Missing required module CBC"} 			  		F{var.CURRENT_FILE} E53301

; Definitions -----------------------------------------------------------------
var DEFAULT_CBC_TEMPERATURE = 30 		; [ºC] Default temperature to use in a
										; print if the CBC was not configured
										; before
var TEMPERATURE_OFF	= 0					; [ºC] Limit temperauture to consider
										; that the CBC is off

; If the CBC target temperature is 0 or lower, the CBC is off so we set up the 
; default temperature
if(!exists(global.cbcTargetTemperature) || (global.cbcTargetTemperature <= var.TEMPERATURE_OFF))
	M118 S{"[CBC] Using default temperature for the CBC: "^var.DEFAULT_CBC_TEMPERATURE^"ºC"}
	M98 P"/macros/cbc/set_temperature.g" T{var.DEFAULT_CBC_TEMPERATURE}

; -----------------------------------------------------------------------------
M99 ; Proper exit