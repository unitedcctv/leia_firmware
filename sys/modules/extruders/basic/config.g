; Description: 	
;	This is a basic extruder that can be used as a reference to create other extruders.
;	It contains:
;		+ 1 x PT1000 temperature sensor
;		+ 1 x 650mA Feeder Motor
;		+ 1 x Heater
;		+ 2 x Fans:
;			+ 1 x Cold end fan (aka "Hotend fan")
;			+ 1 x Layer fan - (aka "Tool fan")
;		+ 1 x Out of filament digital sensor
;		+ 1 x Magnetic filament monitor
; Input Parameters:
;		+ T: Tool 0 or 1 to configure
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/basic/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12600
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12601
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12602
M98 P"/macros/assert/abort_if.g" R{(param.T == 0) && exists(global.MODULE_EXTRUDER_0)}  Y{"A previous EXTRUDER_0 configuration exists"} F{var.CURRENT_FILE} E12603
M98 P"/macros/assert/abort_if.g" R{(param.T == 1) && exists(global.MODULE_EXTRUDER_1)}  Y{"A previous EXTRUDER_1 configuration exists"} F{var.CURRENT_FILE} E12604

; DEFINITIONS --------------------------------------------------------------------------------
; we need to check for existence of globals because this file will be called for each tool

if (!exists(global.exTempLastSetTimes))
	; hardcoded for maximum 2 extruders
	global exTempLastSetTimes = {0,0}
else
	set global.exTempLastSetTimes[param.T] = 0

if (!exists(global.tooldleWaitTime))
	global tooldleWaitTime = 20 * 60 ;[sec] 20 minutes
	
; CAN-FD ID related to the board.
var BOARD_CAN_ID		= {20 + param.T} 		; As a number
var BOARD_CAN_ID_NAME	= {""^var.BOARD_CAN_ID} ; As a string
var boardName = ""
if(var.BOARD_CAN_ID == 20)
	set var.boardName = "T0 board"
else
	set var.boardName = "T1 board"
; Tool Name
var TOOL_NAME			= "Basic-Extruder"

; Temperature sensor of the heater
var TEMP_SENSOR_PORT	= {var.BOARD_CAN_ID_NAME^".temp0"}	; Port
var TEMP_SENSOR_TYPE	= "pt1000"
M98 P"/macros/get_id/sensor.g"	
var TEMP_SENSOR_ID 		= global.sensorId	; ID of the emulated temperature Sensor

; Heater
var HEATER_PORT	  		= {var.BOARD_CAN_ID_NAME^".heater"}	; Port used
M98 P"/macros/get_id/heater.g"
var HEATER_ID 			= global.heaterId	; ID of the Heater
var HEATER_MAX_TEMP		= 320				; [ºC] Max. temperature allowed in
											; the extruder

; Feeder motor
var FEEDER_MOTOR		= {83.0 + param.T}	; Feeder motor
var FEEDER_STEPS_MM		= 27.109			; [1/mm] Steps per mm without microstepping
var FEEDER_MICROSTEPS	= 64				; [] Steps per mm without microstepping
var FEEDER_SPEED		= 3000				; [mm/min] Max speed
var FEEDER_JERK			= 60				; [mm/min] Jerk
var FEEDER_ACCELERATION	= 500				; [mm/s^2] Max acceleration
var FEEDER_CURRENT		= 650				; [mA] Current of the motor

; Tool FAN with tachometer
var FAN_TOOL_PORT 		= {var.BOARD_CAN_ID_NAME^".fan0"}	; Tool FAN
var FAN_TOOL_TACH_PORT	= {"+fan0.tach"}	; Tool FAN tachometer
M98 P"/macros/get_id/fan.g"
var FAN_TOOL_ID 		= global.fanId		; ID to use for the tool Fan
var FAN_TOOL_NAME		= {"tool_t"^param.T}

; Cold-end FAN controlled by temperature
var FAN_COLDEND_PORT 	= {var.BOARD_CAN_ID_NAME^".fan1"}	; Cold-end FAN
M98 P"/macros/get_id/fan.g"
var FAN_COLDEND_ID 		= global.fanId		; ID to use for the cold-end fan
var FAN_COLDEND_TEMP_TRIGGER = 45			; [ºC] Temperature of the hot-end 
											; used to turn on the fan. If it is
											; lower, the fan is OFF.
var FAN_COLDEND_NAME	= {"coldend_t"^param.T}

; Nozzle size
if(param.T == 0)
	global NOZZLE_E0	= 0.6						; [mm]
else 
	global NOZZLE_E1	= 0.6						; [mm]

; CONFIGURATION ------------------------------------------------------------------------------
; Check boards
M98 P"/macros/assert/board_present.g" D{var.BOARD_CAN_ID} Y{"Missing %s"} A{var.boardName,}  F{var.CURRENT_FILE} E12605

; Temperature sensor of the heater
M308 S{var.TEMP_SENSOR_ID} P{var.TEMP_SENSOR_PORT} Y{var.TEMP_SENSOR_TYPE} R2200 A{"temp_t"^param.T^"[°C]"}  ; Emulated temp. sensor
M98 P"/macros/assert/result.g" R{result} Y"Unable to create temp. sensor for the extruder" F{var.CURRENT_FILE} E12606

; Tool FAN with tachometer
M950 F{var.FAN_TOOL_ID} C{""^var.FAN_TOOL_PORT^var.FAN_TOOL_TACH_PORT} Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the tool fan" F{var.CURRENT_FILE} E12607
M106 P{var.FAN_TOOL_ID} S0.0 C{var.FAN_TOOL_NAME}

; Heater
M950 H{var.HEATER_ID} C{var.HEATER_PORT} T{var.TEMP_SENSOR_ID} Q100
M98 P"/macros/assert/result.g" R{result} Y"Unable to create extruder heater" F{var.CURRENT_FILE} E12608
M143 H{var.HEATER_ID} S{var.HEATER_MAX_TEMP}	; Max. Temperature of the heater
M98 P"/macros/assert/result.g" R{result} Y"Unable to set max temperature" F{var.CURRENT_FILE} E12609
; 	NOTE: The next values were obtained using the M303 (autotuning)
M307 H{var.HEATER_ID} R2.016 K0.19:0.000 D8.1 E1.4 S1.00 B0 V24.3	; Setting the parameters of the heater
M98 P"/macros/assert/result_accept_warning.g" R{result}  Y"Unable to set heating parameters" F{var.CURRENT_FILE} E12610 ; It is normal to get warning with M307

; Cold-end FAN controlled by temperature
M950 F{var.FAN_COLDEND_ID} C{var.FAN_COLDEND_PORT} 	Q200
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the cold-end fan" F{var.CURRENT_FILE} E12611
M106 P{var.FAN_COLDEND_ID} H{var.TEMP_SENSOR_ID} T{var.FAN_COLDEND_TEMP_TRIGGER} C{var.FAN_COLDEND_NAME} ; Enable thermostatic mode
M98 P"/macros/assert/result.g" R{result} Y"Unable to enable thermostatic mode for the cold-end fan" F{var.CURRENT_FILE} E12612

; Feeder motor
M98 P"/macros/extruder/config_motor.g" D{var.FEEDER_MOTOR} I{var.FEEDER_MICROSTEPS} T{var.FEEDER_STEPS_MM*var.FEEDER_MICROSTEPS} J{var.FEEDER_JERK} S{var.FEEDER_SPEED} A{var.FEEDER_ACCELERATION} C{var.FEEDER_CURRENT}
M98 P"/macros/assert/abort_if_null.g" R{global.extruderDriverId} Y"Unable to configure the driver" F{var.CURRENT_FILE} E12613

; Tool ----------------------------------------------------------
var NAME_TO_SHOW = {var.TOOL_NAME^" T"^param.T}
M563 P{param.T} D{global.extruderDriverId} H{var.HEATER_ID} F{var.FAN_TOOL_ID} S{var.NAME_TO_SHOW}
M98 P"/macros/assert/result.g" R{result} Y{"Unable to define the tool "^param.T} F{var.CURRENT_FILE} E12614

; Filament monitor
M98 P"/sys/modules/extruders/basic/duet_filament_monitor.g" T{param.T}

; Motor load
M98 P"/sys/modules/extruders/basic/motor_load_sensor.g" T{param.T}

; Configuring the global variable related to the tools
if( param.T == 0 )
	global MODULE_EXTRUDER_0 = 0.1	; Setting the current version of this module	
else
	global MODULE_EXTRUDER_1 = 0.1	; Setting the current version of this module
M98 P"/macros/files/daemon/add.g" F"/sys/modules/extruders/basic/daemon.g"

M118 S{"Configured tool "^param.T}
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit