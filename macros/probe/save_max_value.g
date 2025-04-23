; Description: 
; 	We will check if the max. value of a analog probe is valid and 
;	recorded so it can be used in the future.
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/save_max_value.g"
M118 S{"[PROBE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  		Y{"Missing module PROBES"}					F{var.CURRENT_FILE} E65400
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_SENSOR_ID)}  	Y{"Missing gobal variable PROBE_SENSOR_ID"}	F{var.CURRENT_FILE} E65401
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_MAXIMUM_RANGE)} Y{"Missing gobal variable PROBE_SENSOR_ID"}	F{var.CURRENT_FILE} E65402
; Checking if the values are valid and the sensor is configured properly
M598
M98 P"/macros/assert/abort_if.g" R{!exists(sensors.analog[global.PROBE_SENSOR_ID].lastReading)} Y{"The sensor %s is not configured properly."} A{global.PROBE_SENSOR_ID,} F{var.CURRENT_FILE} E65420
M98 P"/macros/assert/abort_if.g" R{sensors.analog[global.PROBE_SENSOR_ID].lastReading} Y{"The last value of the sensor %s is null"} A{global.PROBE_SENSOR_ID,}	F{var.CURRENT_FILE} E65421

; Definitions -----------------------------------------------------------------
var VARIABLE_NAME = "probe_max_value"			; Name used to record the variable
; When the probe is not touching the bed the probe value should be in this range.
var RANGE_MIN = global.PROBE_MAXIMUM_RANGE[0]	; [um]
var RANGE_MAX = global.PROBE_MAXIMUM_RANGE[1]	; [um]

; Reading the sensor ----------------------------------------------------------
var LAST_READING = sensors.analog[global.PROBE_SENSOR_ID].lastReading

; Checking the range ----------------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{(var.LAST_READING < var.RANGE_MIN)} Y{"The value of the probe is too low: %s"} A{var.LAST_READING,} F{var.CURRENT_FILE}  E65430
M98 P"/macros/assert/abort_if.g" R{(var.LAST_READING > var.RANGE_MAX)} Y{"The value of the probe is too high: %s"} A{var.LAST_READING,} F{var.CURRENT_FILE} E65431

; Record the value ------------------------------------------------------------
M98 P"/macros/variable/save_number.g" N{var.VARIABLE_NAME} V{var.LAST_READING} C1
M118 S{"[PROBE] New max. value recorded: " ^ var.LAST_READING ^"um"}

; -----------------------------------------------------------------------------
M118 S{"[PROBE] Done "^var.CURRENT_FILE}
M99 ; Proper exit