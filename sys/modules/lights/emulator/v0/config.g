; Description: 		Configuration for CBC lighting
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/lights/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_LIGHTS)}  Y{"A previous LIGHTS configuration exists"} F{var.CURRENT_FILE} E13120

; DEFINITIONS --------------------------------------------------------------------------------
var LIGHTS_PORT = "0.out1"				;variable to store the Pin id of the Light port
M98 P"/macros/get_id/output.g"
global LIGHTS_OUTPUT = global.outputId	;variable to store the output id of the Light port

global lightIsEnabled = 0	; Variable to store the current status of the CBC light.
							;	 0 : CBC  Light is OFF
							;	 1 : CBC  Light is ON

; CONFIGURATION ------------------------------------------------------------------------------
M950 P{global.LIGHTS_OUTPUT} C{var.LIGHTS_PORT} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the LIGHT output" F{var.CURRENT_FILE} E13121

; Create links
M98 P"/macros/files/link/create.g" L"/macros/lights/set.g" D"/sys/modules/lights/emulator/v0/set.g"

global MODULE_LIGHTS = 0.1	; Setting the current version of this module

; Setting the lights in the default status
M98 P"/macros/lights/set.g" L1 ; Turn ON the CBC lights

; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit