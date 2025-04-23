; Description: 	
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/extruders/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/extruders/basic/set_offset.g"} F{var.CURRENT_FILE} E12680
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/nozzle/load.g"} F{var.CURRENT_FILE} E12695
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E12681
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} F{var.CURRENT_FILE} E12682
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} F{var.CURRENT_FILE} E12683
M98 P"/macros/assert/abort_if.g" R{(param.T == 0) && exists(global.MODULE_EXTRUDER_0)}  Y{"A previous EXTRUDER_0 configuration exists"} F{var.CURRENT_FILE} E12684
M98 P"/macros/assert/abort_if.g" R{(param.T == 1) && exists(global.MODULE_EXTRUDER_1)}  Y{"A previous EXTRUDER_1 configuration exists"} F{var.CURRENT_FILE} E12685

; DEFINITIONS -----------------------------------------------------------------
; we need to check for existence of globals because this file will be called for each tool

if (!exists(global.exTempLastSetTimes))
	; hardcoded for maximum 2 extruders
	global exTempLastSetTimes = {0,0}
else
	set global.exTempLastSetTimes[param.T] = 0

if (!exists(global.tooldleWaitTime))
	global tooldleWaitTime = 20 * 60 ;[sec] 20 minutes

if(!exists(global.toolFanId))
	global toolFanId = {null,null}	;global variable to store the tool fan ids

var HEATER_PORT 		= {"0.out3", "0.out4"} 	; Heater output for {T0,T1}
var FAN_PORT	 		= {"0.fan0", "0.fan1"} 	; Fan output for {T0,T1}
var MOTOR_DRIVER		= {0.5 , 0.6}			; Motor Driver for {T0,T1}

var MAX_TEMP		= 350			; [ºC] Max. temperature to heat the Emulated Extruder

; Offsets
var OFFSET_X_DEFAULT = { 10, 10}	; [mm] Default offset in X for T0 and T1
var OFFSET_Y_DEFAULT = {-55, 55}	; [mm] Default offset in Y for T0 and T1

M98 P"/macros/get_id/heater.g"
var HEATER_ID = global.heaterId		; ID of the Heater

M98 P"/macros/get_id/sensor.g"		
var TEMP_SENSOR_ID = global.sensorId	; ID of the emulated temperature Sensor

M98 P"/macros/get_id/fan.g"
var FAN_ID = global.fanId				; ID to use for the filament fan
set global.toolFanId[param.T]	= global.fanId

; CONFIGURATION ------------------------------------------------------------------------------
; Check boards
; M98 P"/macros/assert/board_present.g" D{81 + param.T} Y{"Board 8"^{1+param.T} " is required for EXTRUDER"}

M308 S{var.TEMP_SENSOR_ID}  Y"emu-sensor" R100 F1000 C450 A{"temp_t"^param.T^"[°C]"}  	; Emulated temp. sensor
M98 P"/macros/assert/result.g" R{result} Y"Unable to create emulated temp. sensor for the extruder" F{var.CURRENT_FILE} E12686

M950 F{var.FAN_ID} C{var.FAN_PORT[param.T]} Q200				; Create fan 0 for the Extruder 0.
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the fan" F{var.CURRENT_FILE} E12687

M950 H{var.HEATER_ID} C{var.HEATER_PORT[param.T]} T{var.TEMP_SENSOR_ID} Q4
M98 P"/macros/assert/result.g" R{result} Y"Unable to create extruder heater" F{var.CURRENT_FILE} E12688

M143 H{var.HEATER_ID} S{var.MAX_TEMP}				; Max. Temperature of the heater
M98 P"/macros/assert/result.g" R{result} Y"Unable to set max temperature" F{var.CURRENT_FILE} E12689

; The next values were obtained using the M303 (autotuning)
M307 H{var.HEATER_ID} R0.615 K0.074:0.001 D0.1		; Setting the parameters of the heater
M98 P"/macros/assert/result_accept_warning.g" R{result}  Y"Unable to set heating parameters" F{var.CURRENT_FILE} E12690 ; It is normal to get warning with M307

M98 P"/macros/extruder/config_motor.g" D{var.MOTOR_DRIVER[param.T]} I64 T1735 J60 S3000 A500 C650
M98 P"/macros/assert/abort_if_null.g" R{global.extruderDriverId} Y"Unable to configure the driver" F{var.CURRENT_FILE} E12691

; Tool ----------------------------------------------------------
M563 P{param.T} D{global.extruderDriverId} H{var.HEATER_ID} F{var.FAN_ID} S{"Emu-Extruder "^param.T} ; Define tool 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to define the tool" F{var.CURRENT_FILE} E12692

; Tool position
M98 P"/sys/modules/extruders/basic/set_offset.g" T{param.T} X{var.OFFSET_X_DEFAULT[param.T]}  Y{var.OFFSET_Y_DEFAULT[param.T]}

; Load flow rate if exists
M98 P"/macros/extruder/flow_rate/load.g"

; Load nozzle sizes (only once)
if !exists(global.nozzleSizes)
	M98 P"/macros/extruder/nozzle/load.g"
M400

; Configuring the global variable related to the tools
if( param.T == 0 )
	global MODULE_EXTRUDER_0 = 0.1	; Setting the current version of this module
	M98 P"/macros/files/daemon/add.g" F"/sys/modules/extruders/basic/daemon.g"
else
	global MODULE_EXTRUDER_1 = 0.1	; Setting the current version of this module
	if(!exists(global.MODULE_EXTRUDER_0))
		M98 P"/macros/files/daemon/add.g" F"/sys/modules/extruders/basic/daemon.g"

M118 S{"Configured tool "^param.T}


; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit