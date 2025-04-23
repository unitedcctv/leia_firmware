; Description:
; 	Record the max value of the probe. 
;	It is the responsibility of the user that the probe is fully extended!
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/probes/viio/v1/record_max_value.g"
M118 S{"[record_max_value.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/pop_up/ok_abort.g"} F{var.CURRENT_FILE} E15130
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/save_number.g"} F{var.CURRENT_FILE} E15131
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)} Y{"Missing required module PROBES"} F{var.CURRENT_FILE} E15133
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_SENSOR_ID)} Y{"Missing global variable PROBE_SENSOR_ID"} F{var.CURRENT_FILE} E15134
M98 P"/macros/assert/abort_if.g" R{!exists(global.probeParameters)} Y{"Missing global variable probeParameters"} F{var.CURRENT_FILE} E15137

; Set the global probe Parameters [um]
var DEFAULT_PROBE_MAX = 1200; [um]
var DEFAULT_PROBE_PARAMETERS = {-5462.51, 6014.23}
var PROBE_SENSOR_NAME = "dist_bed_ball[um]"
var PROBE_SENSOR_TYPE = "linear-analog"

; redefine sensor with defaults
M308 S{global.PROBE_SENSOR_ID} P{global.PROBE_SENSOR_PORT} Y{var.PROBE_SENSOR_TYPE} F1 B{var.DEFAULT_PROBE_PARAMETERS[0]} C{var.DEFAULT_PROBE_PARAMETERS[1]} A{var.PROBE_SENSOR_NAME}
; wait a bit
G4 S1

M98 P"/macros/assert/abort_if.g" R{!exists(sensors.analog[global.PROBE_SENSOR_ID].lastReading)} Y{"The sensor %s is not configured properly."} A{global.PROBE_SENSOR_ID,} F{var.CURRENT_FILE} E15135
M98 P"/macros/assert/abort_if.g" R{(sensors.analog[global.PROBE_SENSOR_ID].lastReading == null)} Y{"The lastReading value of the sensor %s is null."} A{global.PROBE_SENSOR_ID,} F{var.CURRENT_FILE} E15136

; Definitions
var SAMPLES_AVERAGE = 10			; Amount of samples to average
var SAMPLES_PERIOD	= 0.5			; [sec] Sampling period

M118 S{"[record_max_value.g] Recoding the probe sensor"}
var samples = var.SAMPLES_AVERAGE
if(var.samples < 1)
	set var.samples = 1
var accumulated = 0;
while (var.samples > 0)
	set var.accumulated = sensors.analog[global.PROBE_SENSOR_ID].lastReading + var.accumulated
	G4 S{var.SAMPLES_PERIOD}	; Delay
	set var.samples = var.samples - 1 

; Average the samples
if(var.SAMPLES_AVERAGE == 0)
	set var.samples = 1
else
	set var.samples = var.SAMPLES_AVERAGE
var MAX_VALUE_MEASURED = var.accumulated / var.samples

; Checking that the final value is in the valid range.
M98 P"/macros/assert/abort_if.g" R{(var.MAX_VALUE_MEASURED < global.PROBE_MAXIMUM_RANGE[0])} Y{"Measured value is too low: %sum"} A{var.MAX_VALUE_MEASURED,} F{var.CURRENT_FILE} E15139
M98 P"/macros/assert/abort_if.g" R{(var.MAX_VALUE_MEASURED > global.PROBE_MAXIMUM_RANGE[1])} Y{"Measured value is too high: %sum"} A{var.MAX_VALUE_MEASURED,} F{var.CURRENT_FILE} E15140

M118 S{"[record_max_value.g] Maximum measured: " ^ var.MAX_VALUE_MEASURED ^ "um"}
; Done! Let's save the value
M98 P"/macros/variable/save_number.g" N"probe_max_value" V{var.MAX_VALUE_MEASURED} C1

var PROBE_OFFSET_PARAM = var.MAX_VALUE_MEASURED - var.DEFAULT_PROBE_MAX
set global.probeParameters = {(var.DEFAULT_PROBE_PARAMETERS[0]-var.PROBE_OFFSET_PARAM), (var.DEFAULT_PROBE_PARAMETERS[1]-var.PROBE_OFFSET_PARAM)}
											; [um] parameters used to pass from ADC 
											; to um. NOTE: (!) Should be const but
											; The calibration may need to change it

; redefine sensor with new parameters
M308 S{global.PROBE_SENSOR_ID} P{global.PROBE_SENSOR_PORT} Y{var.PROBE_SENSOR_TYPE} F1 B{global.probeParameters[0]} C{global.probeParameters[1]} A{var.PROBE_SENSOR_NAME}

; -----------------------------------------------------------------------------
M118 S{"[record_max_value.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit