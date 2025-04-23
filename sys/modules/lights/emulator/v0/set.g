; Description:	  This file will control the light from the Studio 3
;	 Input Parameters:
;		  - L: 1 to turn ON , 0 to turn OFF
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/lights/emulator/v0/set.g"

M118 S{"[LIGHTS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_LIGHTS)}  Y{"Missing LIGHTS configuration"} F{var.CURRENT_FILE} E13130
M98 P"/macros/assert/abort_if.g" R{!exists(global.LIGHTS_OUTPUT)}  Y{"Missing global LIGHTS_OUTPUT"} F{var.CURRENT_FILE} E13131
M98 P"/macros/assert/abort_if.g" R{!exists(param.L)} 			   Y{"Missing required input parameter L"} F{var.CURRENT_FILE} E13132
M98 P"/macros/assert/abort_if_null.g" R{param.L}  	  			   Y{"Input parameter L is null"} F{var.CURRENT_FILE} E13133

var OUTPUT_VALUE = ( param.L > 0.5 ) ? 1 : 0 
if(var.OUTPUT_VALUE == global.lightIsEnabled)
	M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The light is already ON"} F{var.CURRENT_FILE} W13130
	M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The light is already OFF"} F{var.CURRENT_FILE} W13131

M42 P{global.LIGHTS_OUTPUT} S{var.OUTPUT_VALUE}
set global.lightIsEnabled = var.OUTPUT_VALUE

; -----------------------------------------------------------------------------
M118 S{"[LIGHTS] Done "^var.CURRENT_FILE}
M99 ; Proper exit
