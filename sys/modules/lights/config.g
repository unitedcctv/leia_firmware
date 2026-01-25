; Description: 		Configuration for CBC and Y-Axis lighting
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/lights/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_LIGHTS)}  Y{"A previous LIGHTS configuration exists"} F{var.CURRENT_FILE} E13102

; DEFINITIONS --------------------------------------------------------------------------------
var CBC_LIGHTS_PORT = "0.out1"				;variable to store the Pin id of the Light port
M98 P"/macros/get_id/output.g"
global CBC_LIGHTS_OUTPUT = global.outputId	;variable to store the output id of the Light port

var Y_AXIS_LIGHTS_PORT = "25.out1"
M98 P"/macros/get_id/output.g"
global Y_AXIS_LIGHTS_OUTPUT = global.outputId

global cbcLightEnabled = 0	 	; Variable to store the current status of the CBC light.
global yAxisLightEnabled = 0
								;	 0 : CBC  Light is OFF
								;	 1 : CBC  Light is ON

; CONFIGURATION ------------------------------------------------------------------------------
M950 P{global.CBC_LIGHTS_OUTPUT} C{var.CBC_LIGHTS_PORT} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the CBC_LIGHTS output"  F{var.CURRENT_FILE} E13103

M950 P{global.Y_AXIS_LIGHTS_OUTPUT} C{var.Y_AXIS_LIGHTS_PORT} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the Y_AXIS_LIGHTS output"  F{var.CURRENT_FILE} E13104

global MODULE_LIGHTS = 0.2	; Setting the current version of this module

; Setting the lights in the default status
M98 P"/sys/modules/lights/set.g" L1 T0	; Turn ON the CBC lights
M98 P"/sys/modules/lights/set.g" L1 T1	; Turn ON the YAxis lights

; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit