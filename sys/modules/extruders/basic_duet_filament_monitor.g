; Description: 	
;	Adds to T0 a duet3d filament monitor with all the available sensors.
; Input Parameters:
;	None - hardcoded for T0
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic_duet_filament_monitor.g"

; Checking global variables and input parameters ------------------------------
; CAN-FD ID related to the board.
var BOARD_CAN_ID		= 20					; T0 board CAN address
var BOARD_CAN_ID_NAME	= "20"				; As a string

; Constant values
var FILAMENT_MONITOR_SCALE		= 760			; [%] Scale to adjust to %
var FILAMENT_ACCUMULATED_SCALE	= 0.0699		; [mm] Scale to adjust to mm
var FILAMENT_RATIO_SCALE		= 1.85			; [%] Scale to adjust to %
if(!exists(global.flowMonitoringActive))
	global flowMonitoringActive = true 			; To enable and disable the flow monitor
; Filament monitor in the object model
M591 D{tools[0].extruders[0]} P3 C{var.BOARD_CAN_ID_NAME^".io1.in"} S1 R5:150 L26.0 E1 A0
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create the filament monitor sensor for tool 0"} F{var.CURRENT_FILE} E12623

; Filament monitor sensors: MOVE
M98 P"/macros/get_id/sensor.g"	
M308 S{global.sensorId} P"nil" Y"linear-analog" A"fila_move_t0[mm/s]" B{var.FILAMENT_MONITOR_SCALE} C0.05 ; Filter enabled
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor sensor for tool 0"} F{var.CURRENT_FILE} E12624

; Filament monitor sensors: ACCUM
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P"nil" Y"linear-analog" A"fila_accu_t0[mm]" B{var.FILAMENT_ACCUMULATED_SCALE}
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor accumulated sensor for tool 0"} F{var.CURRENT_FILE} E12625

; Filament monitor sensors: RATIO
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P"nil" Y"linear-analog" A"fila_rati_t0[%]" B{var.FILAMENT_RATIO_SCALE} C0.2
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor ratio sensor for tool 0"} F{var.CURRENT_FILE} E12626

; Odometer sensor in both directions 
; M98 P"/macros/get_id/sensor.g"
; M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"odomforw" A"odom_forw_t0[km]"
; M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the odometer forward sensor for tool 0"} F{var.CURRENT_FILE} E12627
; M98 P"/macros/get_id/sensor.g"
; M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"odomback" A"odom_back_t0[km]"
; M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the odometer backward sensor for tool 0"} F{var.CURRENT_FILE} E12628


M118 S{"Configured filament monitor for tool 0"}

; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit