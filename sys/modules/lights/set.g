; Description:	  This file will control the CBC and Y-Axis lights from the Studio 3
;	 Input Parameters:
;		  - L: 1 to turn ON , 0 to turn OFF
;		  - (optional) T: 0: CBC, 1: Y-Axis, None: All lights
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/lights/set.g"

M118 S{"[LIGHTS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_LIGHTS)}  Y{"Missing LIGHTS configuration"} F{var.CURRENT_FILE} E13105
M98 P"/macros/assert/abort_if.g" R{!exists(global.CBC_LIGHTS_OUTPUT)}  Y{"Missing global CBC_LIGHTS_OUTPUT"} F{var.CURRENT_FILE} E13106
M98 P"/macros/assert/abort_if.g" R{!exists(global.Y_AXIS_LIGHTS_OUTPUT)} Y{"Missing global Y_AXIS_LIGHTS_OUTPUT"} F{var.CURRENT_FILE} E13107
M98 P"/macros/assert/abort_if.g" R{!exists(param.L)} 			   Y{"Missing required input parameter L"} F{var.CURRENT_FILE} E13109
M98 P"/macros/assert/abort_if_null.g" R{param.L}  	  			   Y{"Input parameter L is null"} F{var.CURRENT_FILE} E13114

var OUTPUT_VALUE = ( param.L > 0.5 ) ? 1 : 0 

if (exists(param.T) && (param.T == 0))
	if(var.OUTPUT_VALUE == global.cbcLightEnabled)
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The CBC light is already ON"} F{var.CURRENT_FILE} W13112
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The CBC light is already OFF"} F{var.CURRENT_FILE} W13113
	M42 P{global.CBC_LIGHTS_OUTPUT} S{var.OUTPUT_VALUE}
	if(var.OUTPUT_VALUE == 0) 
		M118 S{"[LIGHTS] CBC lights turned OFF"}
	elif(var.OUTPUT_VALUE == 1)
		M118 S{"[LIGHTS] CBC lights turned ON"}
	set global.cbcLightEnabled = var.OUTPUT_VALUE

elif (exists(param.T) && (param.T == 1))
	if(var.OUTPUT_VALUE == global.yAxisLightEnabled)
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The y-Axis light is already ON"} F{var.CURRENT_FILE} W13114
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The y-Axis light is already OFF"} F{var.CURRENT_FILE} W13115
	M42 P{global.Y_AXIS_LIGHTS_OUTPUT} S{var.OUTPUT_VALUE}
	if(var.OUTPUT_VALUE == 0) 
		M118 S{"[LIGHTS] Y-Axis lights turned OFF"}
	elif(var.OUTPUT_VALUE == 1)
		M118 S{"[LIGHTS] Y-Axis lights turned ON"}
	set global.yAxisLightEnabled = var.OUTPUT_VALUE

else
	if(var.OUTPUT_VALUE == global.cbcLightEnabled)
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The CBC light is already ON"} F{var.CURRENT_FILE} W13116
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The CBC light is already OFF"} F{var.CURRENT_FILE} W13117
	if(var.OUTPUT_VALUE == global.yAxisLightEnabled)
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The y-Axis light is already ON"} F{var.CURRENT_FILE} W13118
		M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The y-Axis light is already OFF"} F{var.CURRENT_FILE} W13119
	M42 P{global.CBC_LIGHTS_OUTPUT} S{var.OUTPUT_VALUE}
	M42 P{global.Y_AXIS_LIGHTS_OUTPUT} S{var.OUTPUT_VALUE}
	if(var.OUTPUT_VALUE == 0)
		M118 S{"[LIGHTS] All lights turned OFF"}
	elif(var.OUTPUT_VALUE == 1)
		M118 S{"[LIGHTS] All lights turned ON"}
	set global.cbcLightEnabled = var.OUTPUT_VALUE
	set global.yAxisLightEnabled = var.OUTPUT_VALUE

; -----------------------------------------------------------------------------
M118 S{"[LIGHTS] Done "^var.CURRENT_FILE}
M99 ; Proper exit