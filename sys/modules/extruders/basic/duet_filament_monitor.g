; Description: 	
;	Adds to the current tool a duet3d filament monitor with all the available sensors.
; Input Parameters:
;	- T: Tool 0 or 1 where the filament monitor is connected
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic/duet_filament_monitor.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12620
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12621
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12622

; CAN-FD ID related to the board.
var BOARD_CAN_ID		= {20 + param.T} 		; As a number
var BOARD_CAN_ID_NAME	= {""^var.BOARD_CAN_ID} ; As a string

; Constant values
var FILAMENT_MONITOR_SCALE		= 760			; [%] Scale to adjust to %
var FILAMENT_ACCUMULATED_SCALE	= 0.0699		; [mm] Scale to adjust to mm
var FILAMENT_RATIO_SCALE		= 1.85			; [%] Scale to adjust to %
if(!exists(global.flowMonitoringActive))
	global flowMonitoringActive = true 			; To enable and disable the flow monitor
; Filament monitor in the object model
M591 D{tools[param.T].extruders[0]} P3 C{var.BOARD_CAN_ID_NAME^".io1.in"} S1 R5:150 L26.0 E1 A0
M98 P"/macros/assert/result.g" R{result} Y{"Unable to create the filament monitor sensor for tool %s"} A{param.T,} F{var.CURRENT_FILE} E12623

; Filament monitor sensors: MOVE
M98 P"/macros/get_id/sensor.g"	
M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"filament" A{"fila_move_t"^param.T^"[mm/s]"} B{var.FILAMENT_MONITOR_SCALE} C0.05 ; Filter enabled
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor sensor for tool %s"} A{param.T,} F{var.CURRENT_FILE} E12624

; Filament monitor sensors: ACCUM
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"totfilam" A{"fila_accu_t"^param.T^"[mm]"} B{var.FILAMENT_ACCUMULATED_SCALE}
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor accumulated sensor for tool %s"} A{param.T,} F{var.CURRENT_FILE} E12625

; Filament monitor sensors: RATIO
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"filaratio" A{"fila_rati_t"^param.T^"[%]"} B{var.FILAMENT_RATIO_SCALE} C0.2
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the filament monitor ratio sensor for tool %s"} A{param.T,} F{var.CURRENT_FILE} E12626

; Odometer sensor in both directions 
; M98 P"/macros/get_id/sensor.g"
; M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"odomforw" A{"odom_forw_t"^param.T^"[km]"}
; M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the odometer forward sensor for tool "^param.T} F{var.CURRENT_FILE} E12627
; M98 P"/macros/get_id/sensor.g"
; M308 S{global.sensorId} P{var.BOARD_CAN_ID_NAME^".dummy"} Y"odomback" A{"odom_back_t"^param.T^"[km]"}
; M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the odometer backward sensor for tool "^param.T} F{var.CURRENT_FILE} E12628


M118 S{"Configured filament monitor for tool "^param.T}

; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit