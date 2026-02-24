; Description: 	
;	Load sensor in the extruder
; Input Parameters:
;	None - hardcoded for T0
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic_motor_load_sensor.g"

; Checking global variables and input parameters ------------------------------
; CAN-FD ID related to the board.
var BOARD_CAN_ID		= 20				 ; T0 board CAN address
var MOTOR_CAN_ID_NAME	= "20.0"			 ; As a string

; Creating the load sensor of the motor in the extruder
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P"nil" Y"linear-analog" A"load_t0_avg[]" C10000.0
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create sensor for tool 0"} F{var.CURRENT_FILE} E12633

M118 S{"Configured motor load sensor for tool 0"}

; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit
