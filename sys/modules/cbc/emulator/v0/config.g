; Description: 	Chamber heater:
; 	The Heater installed in the CBC can be controlled as Chamber device or as a fan with 
;	the inverted output. If the useChamber variable is defined it will use the chamber an 
;	set it up as a "heater", if it is not it will be a fan.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/cbc/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_CBC)}  Y{"A previous CBC configuration exists"} F{var.CURRENT_FILE} E11140

; DEFINITIONS --------------------------------------------------------------------------------
var HEATER_OUT	  	= "0.out2"	; Heater output
global CBC_MAX_TEMP	= 65		; [ºC] Max. temperature to heat the CBC

M98 P"/macros/get_id/heater.g"
global CBC_HEATER = global.heaterId				; ID of the Heater of the Chamber

M98 P"/macros/get_id/sensor.g"
global CBC_TEMP_SENSOR_A = global.sensorId		; ID of the temperature Sensor of the CBC

M98 P"/macros/get_id/sensor.g"
global AMB_TEMP_SENSOR = global.sensorId		; ID of the ambient temperture Sensor of the CBC

if (!exists(global.cbcLastSetTime))
	; hardcoded for maximum 2 extruders
	global cbcLastSetTime = 0
else
	set global.cbcLastSetTime = 0

if (!exists(global.cbcIdleWaitTime))
	global cbcIdleWaitTime = 120 * 60 ;[sec] 2 hours

; CONFIGURATION ------------------------------------------------------------------------------
M308 S{global.CBC_TEMP_SENSOR_A}  Y"emu-sensor" R450 F350 C150 A"temp_cbc[°C]"  ; emulated CBC Temperature
M98 P"/macros/assert/result.g" R{result} Y"Unable to create emulated CBC Temperature" F{var.CURRENT_FILE} E11141

M308 S{global.AMB_TEMP_SENSOR}  Y"mcutemp" A"temp_amb[°C]"  ; ambient Temperature using MCU temperature
M98 P"/macros/assert/result.g" R{result} Y"Unable to create ambient temperture sensor" F{var.CURRENT_FILE} E11142

M950 H{global.CBC_HEATER} C{var.HEATER_OUT} T{global.CBC_TEMP_SENSOR_A} Q4
M98 P"/macros/assert/result.g" R{result} Y"Unable to create CBC heater" F{var.CURRENT_FILE} E11143

M143 H{global.CBC_HEATER} S{global.CBC_MAX_TEMP}	; Max. Temperature of the CBC
M98 P"/macros/assert/result.g" R{result} Y"Unable to set max temperature" F{var.CURRENT_FILE} E11144

; The next values were obtained using the M303 (autotuning)
M307 H{global.CBC_HEATER} R0.141 K0.687:0.068 D0.1   	; Setting the parameters of the heater
M98 P"/macros/assert/result_accept_warning.g" R{result}  Y"Unable to set heating parameters" F{var.CURRENT_FILE} E11145 ; It is normal to get warning with M307

M141 H{global.CBC_HEATER}								; map heated bed to heater 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to map heater with CBC" F{var.CURRENT_FILE} E11146

; Creating the links
M98 P"/macros/files/link/create.g" L"/macros/cbc/set_temperature.g" D"/sys/modules/cbc/emulator/v0/set_temperature.g"

global MODULE_CBC = 0.1	; Setting the current version of this module

; Init - CBC Heater and Output Fans
M98 P"/macros/cbc/set_temperature.g"							; Turn off the CBC

M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit