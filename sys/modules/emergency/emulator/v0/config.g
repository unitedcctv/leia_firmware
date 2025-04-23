; Description:
;
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_EMERGENCY)}  Y{"A previous EMERGENCY configuration exists"} F{var.CURRENT_FILE} E12150

; DEFINITIONS --------------------------------------------------------------------------------
var EMERGENCY_DOOR_ALL_INPUTS 				= {"0.io6.in",}				; List of boards with emergency input
var EMERGENCY_DOOR_INPUT_TRIGGER 		= "0.io6.in" 				; This pin will trigger the event.

M98 P"/macros/get_id/trigger.g"
var EMERGENCY_TRIGGER_ID = global.triggerId 				; Trigger id called when the event is 
															; detected in the input EMERGENCY_DOOR_INPUT_TRIGGER.

var emergencyInputs = vector(#var.EMERGENCY_DOOR_ALL_INPUTS, -1 )		; Array with inputs ids of the emergencies

; Global variables
global emergencyDoorIsTriggered 	= false
; global emergencyGeneralIsTriggered 	= false

; CONFIGURATION ------------------------------------------------------------------------------

; Setting the emergency pins in the expansion boards.
var idx = 0
while (var.idx < #var.EMERGENCY_DOOR_ALL_INPUTS)
	M98 P"/macros/get_id/input.g"
	M950 J{global.inputId} C{var.EMERGENCY_DOOR_ALL_INPUTS[var.idx]}	; Create the input
	M98 P"/macros/assert/result.g" R{result} Y{"Unable to create input " ^ var.idx ^ " for the emergency"} F{var.CURRENT_FILE} E12151
	set var.emergencyInputs[var.idx] = global.inputId
	if(var.EMERGENCY_DOOR_ALL_INPUTS[var.idx] == var.EMERGENCY_DOOR_INPUT_TRIGGER)
		M581 P{global.inputId} T{var.EMERGENCY_TRIGGER_ID} S0	;Configure the emergency trigger event
		M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger H2L event for the emergency" F{var.CURRENT_FILE}  E12152
		M581 P{global.inputId} T{var.EMERGENCY_TRIGGER_ID} S1	;Configure the emergency trigger event
		M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger L2H event for the emergency" F{var.CURRENT_FILE}  E12153
		set global.emergencyDoorIsTriggered = { (sensors.gpIn[var.emergencyInputs[var.idx]].value > 0.5) ? true : false}
	set var.idx = var.idx + 1

global EMERGENCY_INPUTS = var.emergencyInputs

; Create links
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ var.EMERGENCY_TRIGGER_ID ^ ".g"} 	D"/sys/modules/emergency/emulator/v0/trigger_emergency_door.g"

global MODULE_EMERGENCY = 0.1	; Setting the current version of this module

; Call the macrosto update the states of the global variables.
M98 P"/sys/modules/emergency/emulator/v0/trigger_emergency_door.g"

; -----------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit