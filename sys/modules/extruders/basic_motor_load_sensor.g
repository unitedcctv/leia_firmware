; Description: 	
;	Load sensor in the extruder
; Input Parameters:
;	- T: Tool 0 or 1 where the filament monitor is connected
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic_motor_load_sensor.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12630
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12631
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12632

; CAN-FD ID related to the board.
var BOARD_CAN_ID		= {20 + param.T} 		 ; As a number
var MOTOR_CAN_ID_NAME	= {""^var.BOARD_CAN_ID^".0"} ; As a string

; Creating the load sensor of the motor in the extruder
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P"nil" Y"linear-analog" A{"load_t"^param.T^"_avg[]"} C10000.0
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create sensor of the tool %s"} A{param.T,} F{var.CURRENT_FILE} E12633

M118 S{"Configured motor load sensor for tool "^param.T}

; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit
