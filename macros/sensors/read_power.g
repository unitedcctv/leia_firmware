; Description: 	
;		-To check the testvoltage
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/sensors/read_power.g"
M118 S{"[read_power.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Getting global variables prepared -------------------------------------------
if(!exists(global.powerMeterValueStart))
	global powerMeterValueStart = null
	G4 S0.1
else 
	set global.powerMeterValueStart = null
M400

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 	  R{!exists(global.ELEC_POWER_SENSOR)}  							Y{"Missing global variable ELEC_POWER_SENSOR"}   F{var.CURRENT_FILE} E67200
M98 P"/macros/assert/abort_if_null.g" R{global.ELEC_POWER_SENSOR }  									Y{"Global variable ELEC_POWER_SENSOR is null"}   F{var.CURRENT_FILE} E67201
M98 P"/macros/assert/abort_if.g" 	  R{!exists(sensors.analog[global.ELEC_POWER_SENSOR].lastReading)}  Y{"Power meter sensor not properly configured"}  F{var.CURRENT_FILE} E67202
M98 P"/macros/assert/abort_if_null.g" R{sensors.analog[global.ELEC_POWER_SENSOR].lastReading}  			Y{"Power meter sensor is measuring null"}  		 F{var.CURRENT_FILE} E67203

; Reading the sensor ----------------------------------------------------------
set global.powerMeterValueStart = sensors.analog[global.ELEC_POWER_SENSOR].lastReading
M118 S{"[read_power.g] The accumulated power is "^global.powerMeterValueStart^"kWh"}
; save the value to persistent variable to recover after power outrage
M98 P"/macros/variable/save_number.g" N"global.powerMeterValueStart" V{global.powerMeterValueStart} C1
; -----------------------------------------------------------------------------
M118 S{"[read_power.g] Done "^var.CURRENT_FILE}
M99