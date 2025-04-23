	; Description: 	
	;	Creation of an LED strip of an extruder
	; Input Parameters:
	;	- T: Tool 0 or 1 where the filament monitor is connected
	; Example:
	;	M98 P"/sys/modules/extruders/basic/led_strip.g" T0
	;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic/led_strip.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12662
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12663
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12664

; CAN-FD ID related to the board.
var BOARD_CAN_ID		= {81 + param.T} 		; As a number
var BOARD_CAN_ID_NAME	= {""^var.BOARD_CAN_ID} ; As a string
var LED_PORT 			= {var.BOARD_CAN_ID_NAME^".led"}

; Create the LED strip
M950 E{param.T} C{var.LED_PORT}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the LED strip" F{var.CURRENT_FILE} E12665

M98 P"/macros/extruder/led_strip/set_mode.g" T{param.T} S"idle"

; -----------------------------------------------------------------------------
M99