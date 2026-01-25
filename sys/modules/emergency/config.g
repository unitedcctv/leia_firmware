; Description:		This file creates the emergency input triggers
;
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_EMERGENCY)}  Y{"A previous EMERGENCY configuration exists"} F{var.CURRENT_FILE} E12170

; DEFINITIONS --------------------------------------------------------------------------------
var EMERGENCY_DOOR_ALL_INPUTS 	 = {"10.emerg", "25.emerg", "30.emerg", "31.emerg", "0.io4.in"}		; List of boards with emergency input
var EMERGENCY_DOOR_INPUT_TRIGGER = "25.emerg" 				; This pin will trigger the event.

M98 P"/macros/get_id/trigger.g"
var EMERGENCY_TRIGGER_ID = global.triggerId 	; Trigger id called when the event is 
												; detected in the input EMERGENCY_DOOR_INPUT_TRIGGER.

; We support that the 48V are connected to multiple inputs
var EMERGENCY_GENERAL_INPUTS		= {"0.io5.in", "0.io6.in", "0.io7.in"}	; These pins will trigger the 48V event.
M98 P"/macros/get_id/trigger.g"
var EMERGENCY_GENERAL_TRIGGER_ID 	= global.triggerId 	; Trigger id called when the event is 
														; detected in the input V48_DETECT.

var EMERGENCY_DISABLE_CTRL 			= "0.fan3"			; Output used to disable the 48V if there is an emergency
M98 P"/macros/get_id/output.g"
global EMERGENCY_DISABLE_CTRL		= global.outputId	; Output used to turn off the 48V signal

var emergencyInputs = vector(#var.EMERGENCY_DOOR_ALL_INPUTS, -1 )		; Array with inputs ids of the emergencies

var totalPorts = #var.EMERGENCY_GENERAL_INPUTS
var v48Inputs = vector(var.totalPorts,-1)
var inputsCounter = 0
while(var.inputsCounter < #var.EMERGENCY_GENERAL_INPUTS)
	M98 P"/macros/get_id/input.g"
	set var.v48Inputs[var.inputsCounter] = global.inputId
	set var.inputsCounter = var.inputsCounter + 1
global EMERGENCY_GENERAL_INPUTS = var.v48Inputs

; Global variables ------------------------------------------------------------
; (!) For safety, they are default triggered.
global emergencyDoorIsTriggered 	= true 					
global emergencyGeneralIsTriggered 	= true

; CONFIGURATION ---------------------------------------------------------------

; Checking for board
M98 P"/macros/assert/board_present.g" D10 Y"X axis motor board is required for EMERGENCY" F{var.CURRENT_FILE} E12171
M98 P"/macros/assert/board_present.g" D25 Y"Y axis motor board is  required for EMERGENCY" F{var.CURRENT_FILE} E12172
M98 P"/macros/assert/board_present.g" D30 Y"Z axis left motor board is required for EMERGENCY" F{var.CURRENT_FILE} E12173
M98 P"/macros/assert/board_present.g" D31 Y"Z axis right motor board is required for EMERGENCY" F{var.CURRENT_FILE} E12174

; Setting the emergency pins in the expansion boards.
var idx = 0
while (var.idx < #var.EMERGENCY_DOOR_ALL_INPUTS)
	M98 P"/macros/get_id/input.g"
	M950 J{global.inputId} C{var.EMERGENCY_DOOR_ALL_INPUTS[var.idx]}	; Create the input
	M98 P"/macros/assert/result.g" R{result} Y{"Unable to create input " ^ var.idx ^ " for the emergency"} F{var.CURRENT_FILE} E12176
	set var.emergencyInputs[var.idx] = global.inputId
	if(var.EMERGENCY_DOOR_ALL_INPUTS[var.idx] == var.EMERGENCY_DOOR_INPUT_TRIGGER)
		M581 P{global.inputId} T{var.EMERGENCY_TRIGGER_ID} S0	;Configure the emergency trigger event
		M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger H2L event for the emergency" F{var.CURRENT_FILE} E12177
		M581 P{global.inputId} T{var.EMERGENCY_TRIGGER_ID} S1	;Configure the emergency trigger event
		M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger L2H event for the emergency" F{var.CURRENT_FILE} E12178
		set global.emergencyDoorIsTriggered = { (sensors.gpIn[var.emergencyInputs[var.idx]].value > 0.5) ? true : false }
	set var.idx = var.idx + 1

global EMERGENCY_INPUTS = var.emergencyInputs

; Setting the 48V inputs
var v48Idx = 0
while(var.v48Idx < #global.EMERGENCY_GENERAL_INPUTS)
	M950 J{global.EMERGENCY_GENERAL_INPUTS[var.v48Idx]} C{var.EMERGENCY_GENERAL_INPUTS[var.v48Idx]}		; Create the input
	M98 P"/macros/assert/result.g" R{result} Y{"Unable to create input for the 48V"} F{var.CURRENT_FILE} E12179
	M581 P{global.EMERGENCY_GENERAL_INPUTS[var.v48Idx]} T{var.EMERGENCY_GENERAL_TRIGGER_ID} S0		; Configure the 48V Event
	M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger H2L event for the 48V" F{var.CURRENT_FILE} E12180
	M581 P{global.EMERGENCY_GENERAL_INPUTS[var.v48Idx]} T{var.EMERGENCY_GENERAL_TRIGGER_ID} S1		; Configure the 48V Event
	M98 P"/macros/assert/result.g" R{result} Y"Unable to set the trigger L2H event for the 48V" F{var.CURRENT_FILE} E12181
	set var.v48Idx = var.v48Idx + 1

; Output used to trigger the output
M950 P{global.EMERGENCY_DISABLE_CTRL} C{var.EMERGENCY_DISABLE_CTRL} Q200
M42 P{global.EMERGENCY_DISABLE_CTRL} S1 ; By default it is ON!

; Create links
; (!) We are using the viio/v0 files as there are no changes 
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ var.EMERGENCY_TRIGGER_ID ^ ".g"} 			D"/sys/modules/emergency/trigger_emergency_door.g"
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ var.EMERGENCY_GENERAL_TRIGGER_ID ^ ".g"} 	D"/sys/modules/emergency/trigger_emergency_general.g"

global MODULE_EMERGENCY = 0.2	; Setting the current version of this module

; Call the macros to update the states of the global variables.
M98 P"/sys/modules/emergency/trigger_emergency_door.g"
M98 P"/sys/modules/emergency/read_emergency_general.g"

; -----------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit