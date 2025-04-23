; Description: 	
;   In this modules we will obtain the data form the power-meter sensor installed in the 
;   machine. It is monitoring the following variables:
;	   - Voltage: AC input voltage
;	   - Current: AC input current
;	   - Wattage: Current and accumulated power consumption.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/power_meter/viio/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_POWER_METER)}  	Y{"A previous POWER_METER configuration exists"} F{var.CURRENT_FILE} E14610

; DEFINITIONS --------------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
global ELEC_POWER_SENSOR = global.sensorId		; ID of the accumulated electrical power
var VOLTAGE_VALID_RANGE = { 90, 250 }			; [V] Min an Max values


; CONFIGURATION ------------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
var VOLTAGE_SENSOR = global.sensorId
M308 S{var.VOLTAGE_SENSOR} 			Y"pmvolt"		A"volt_ac[V]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create voltage sensor using the power meter" F{var.CURRENT_FILE} E14611

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} 			Y"pmamp"		A"curr_ac[A]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create current sensor using the power meter" F{var.CURRENT_FILE} E14612

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}				Y"pmwatt"		A"power_ac[W]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create power sensor using the power meter" F{var.CURRENT_FILE} E14613

M308 S{global.ELEC_POWER_SENSOR} 	Y"pmkwhp"		A"power_tot[kWh]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create total power sensor using the power meter" F{var.CURRENT_FILE} E14614

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}			 Y"pmhours"			A"time_tot_on[h]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create total time ON sensor using the power meter" F{var.CURRENT_FILE} E14615

G4 S2
M400

; Check that the values are valid ---------------------------------------------
var VOLTAGE_READ = sensors.analog[var.VOLTAGE_SENSOR].lastReading
M98 P"/macros/assert/abort_if.g" R{ (var.VOLTAGE_READ < var.VOLTAGE_VALID_RANGE[0]) }  	Y{"Low voltage detected in the power-meter: %s"} A{var.VOLTAGE_READ,}  F{var.CURRENT_FILE} E14616
M98 P"/macros/assert/abort_if.g" R{ (var.VOLTAGE_READ > var.VOLTAGE_VALID_RANGE[1]) }  	Y{"High voltage detected in the power-meter"} F{var.CURRENT_FILE} E14617

global MODULE_POWER_METER = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit