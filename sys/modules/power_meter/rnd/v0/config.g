; Description: 	
;   In this modules we will obtain the data form the power-meter sensor installed in the 
;   machine. It is monitoring the following variables:
;	   - Voltage: AC input voltage
;	   - Current: AC input current
;	   - Wattage: Current and accumulated power consumption.
;   In the R&D machines, the voltage, current and wattage is filtered.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/power_meter/rnd/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_POWER_METER)}  	Y{"A previous POWER_METER configuration exists"} F{var.CURRENT_FILE} E14600

; DEFINITIONS --------------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
global ELEC_POWER_SENSOR = global.sensorId		; ID of the accumulated electrical power

; CONFIGURATION ------------------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} 			Y"pmvolt"		A"volt_ac[V]"   C0.05	; Filter enabled
M98 P"/macros/assert/result.g" R{result} Y"Unable to create voltage sensor using the power meter" F{var.CURRENT_FILE} E14601

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId} 			Y"pmamp"		A"curr_ac[A]"   C0.05	; Filter enabled
M98 P"/macros/assert/result.g" R{result} Y"Unable to create current sensor using the power meter" F{var.CURRENT_FILE} E14602

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}				Y"pmwatt"		A"power_ac[W]"  C0.05	; Filter enabled
M98 P"/macros/assert/result.g" R{result} Y"Unable to create power sensor using the power meter" F{var.CURRENT_FILE} E14603

M308 S{global.ELEC_POWER_SENSOR} 	Y"pmkwhp"		A"power_tot[kWh]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create total power sensor using the power meter" F{var.CURRENT_FILE} E14604

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}			 Y"pmhours"		A"time_tot_on[h]"
M98 P"/macros/assert/result.g" R{result} Y"Unable to create total time ON sensor using the power meter" F{var.CURRENT_FILE} E14605

global MODULE_POWER_METER = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit