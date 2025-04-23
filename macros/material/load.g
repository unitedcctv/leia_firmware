; Description:
;    macro to load the filament in the selected tool or select a tool if specified. Does not run any tool change macro files (P0)
;	
; Input Parameters:
;   - T : tool index
; Example:
;	M98 P"/macros/material/load.g" T0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/material/load.g"
M118 S{"[load.g] Starting "^var.CURRENT_FILE^ "I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

;Definitions-------------------------------------------------------------------
var EXTRUSION_LENGTH 	= (network.hostname == "emulator") ? 10 : 150	;[mm]
var CHECK_LENGTH 		= 10	;[mm]
var loopCounter 		= 1
var TOOL 				= param.T
var FEED_RATE			= 2*60	;[mm/s]
var TIME_OUT			= 30	;[s]
var TOLERANCE 			= 5
var timeOutLoop			= 0
var MAX_NUM_CHECKS 	= 3
; Load Procedure -------------------------------------------------------------
if(!exists(global.forceAbort))
	global forceAbort = false
; set relative extrusion mode
M83

M98 P"/macros/report/event.g" Y{"Push the filament in until the extruder grabs it"} F{var.CURRENT_FILE} V62030
;checking the presence of the filament in the oof sensor
if(exists(global.OOF_INPUTS_ID) && (sensors.gpIn[global.OOF_INPUTS_ID[param.T]].value == 0))
	while ((sensors.gpIn[global.OOF_INPUTS_ID[param.T]].value == 0) && ( var.timeOutLoop <= var.TIME_OUT))		
		G4 S1
		set var.timeOutLoop = var.timeOutLoop + 1
		M400
		if (global.forceAbort)
			M118 S"[load.g] Aborted via global.ForceAbort"
			M99
	M400
	;time out after 30s
	M98 P"/macros/assert/abort_if.g" R{var.timeOutLoop > var.TIME_OUT}  Y{"Could not detect filament in T%s after 30 seconds. Please try loading again"} A{param.T,} F{var.CURRENT_FILE} E62030


; if we have an encoder, we try to detect if filament was grabbed
var hasEncoder = false
M98 P"/macros/sensors/find_by_name.g" N{"fila_accu_t"^param.T^"[mm]"}
M400
if exists(global.sensorIndex) && global.sensorIndex != null
	set var.hasEncoder = true

; Grabbing the filament
while var.hasEncoder
	var ENCODER_BASELINE = sensors.analog[global.sensorIndex].lastReading

	; extrude
	M118 S{"[load.g] Grabbing 10mm of the filament"}
	G1 E{var.CHECK_LENGTH} F{var.FEED_RATE}
	M400	

	var GRABBED_LENGTH = abs(var.ENCODER_BASELINE - sensors.analog[global.sensorIndex].lastReading)
	var DIFFERENCE = var.CHECK_LENGTH - var.GRABBED_LENGTH

	; check if the difference btw the commanded extrusion and filament accu value is out of tolerance
	if(var.DIFFERENCE <= var.TOLERANCE)
		M118 S{"[load.g] Grabbing 10mm successful"}
		break
	
	; check if we tried too many times
	if(iterations + 1 >= var.MAX_NUM_CHECKS)
		M98 P"/macros/report/event.g" Y{"Could not grab filament in T%s. Please check extruder and try loading again"} A{param.T,} F{var.CURRENT_FILE} V62032
		M99
	if (global.forceAbort)
		M118 S"[load.g] Aborted via global.forceAbort"
		M99

	M118 S{"[load.g] Difference is greater than "^var.TOLERANCE^" , loading again"}

M98 P"/macros/report/event.g" Y{"Purging %smm"} A{var.EXTRUSION_LENGTH,} F{var.CURRENT_FILE} V62033
G1 E{var.EXTRUSION_LENGTH} F{var.FEED_RATE}
M400

M98 P"/macros/report/event.g" Y{"T%s material loaded successfully"} A{param.T,} F{var.CURRENT_FILE} V62031
M400
;--------------------------------------------------------------------------------------------------------
M118 S{"[load.g] Done "^var.CURRENT_FILE}
M99
