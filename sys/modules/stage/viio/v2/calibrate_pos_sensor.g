;Description: Calibrate the position sensor for Tool position to match UW position
;Process:
;   The position sensor is a linear sensor that will encode the bottom about 6mm of the UW position.
;   The calibration will be done by moving the tool to 5 different positions and measuring the sensor reading.
;   A linear regression will be performed to find the slope and intercept of the sensor reading vs position.
;   The calibration will be verified by moving the tool to the 5 positions and checking the sensor reading.
;   If the deviation is more than 0.05mm, the calibration will be considered invalid.
;   The calibration parameters will be saved to a persistent variable.
;   The sensor will be configured with the new parameters.

var CURRENT_FILE = "/sys/modules/stage/viio/v2/calibrate_pos_sensor.g"
M118 S{"[calibrate_pos_sensor.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Initialize variables
var TOOL = exists(param.T) && param.T==1 ? 1 : 0
var SENSOR_ID = global.TOUCH_BED_SENSOR_IDS[var.TOOL]    ; Touch sensor ID
var ADC_FULL_SCALE = 3300                                ; [mV] Full scale of the ADC
var NUM_POINTS = 5                                       ; Number of points to sample
var CALIB_THRESHOLD = 0.075                               ; [mm] Deviation threshold
var SAFE_UW_MINIMUM = var.TOOL == 0 ? move.axes[3].max-3 : move.axes[4].max-3

var RANGE = global.TOUCH_BED_VALID_RANGE
var POINTS = vector(var.NUM_POINTS, 0)
var NUM_SAMPLES = 5
var SAMPLE_MS = 500
var measurements = vector(var.NUM_POINTS, 0)

while iterations < var.NUM_POINTS
	var targetPosition = var.RANGE[0] + (var.RANGE[1] - var.RANGE[0]) * iterations / (var.NUM_POINTS - 1)
	set var.POINTS[iterations] = var.targetPosition


if global.touchLinearInstalled[var.TOOL] == false
	M98 P"/macros/report/warning.g" Y{"T%s skipping touch sensor calibration because no linear sensor installed"} A{param.T,} F{var.CURRENT_FILE} W16440
	M99
M400

; home the u or w axis if not homed
if var.TOOL == 0
	if move.axes[3].homed == false
		M98 P"/sys/homeu.g"
else
	if move.axes[4].homed == false
		M98 P"/sys/homew.g"
M400

M118 S{"[calibrate_pos_sensor.g] Using Sensor ID: " ^ var.SENSOR_ID ^ " for T" ^ var.TOOL}

; Set up sensor with default values
M308 S{var.SENSOR_ID} P{"70.hall"^var.TOOL} Y"linear-analog" F1 B0 C{var.ADC_FULL_SCALE} A{"hall_ext_"^var.TOOL^"[mV]"}
M400
; initialize axis minimum
if var.TOOL == 0
	M208 U0 S1
else
	M208 W0 S1
M400
G4 S1 ; wait for a second
M400

; Initialize variables for linear regression
var n = #var.POINTS
var Sx = 0
var Sy = 0
var Sxx = 0
var Sxy = 0
var loopError = 0
; Collect measurements and fail early if deviation is detected
while iterations < var.n
	; Move tool axis to sample point
	var targetPosition = var.POINTS[iterations]
	if var.TOOL == 0
		G1 U{var.targetPosition} F1000
	else
		G1 W{var.targetPosition} F1000
	M400
	G4 S2
	M400
	; Read sensor value
	var reading = 0
	while iterations < var.NUM_SAMPLES
		set var.reading = var.reading + sensors.analog[var.SENSOR_ID].lastReading
		G4 P{var.SAMPLE_MS}
	M400
	set var.reading = var.reading / var.NUM_SAMPLES

	set var.measurements[iterations] = var.reading

	; Update sums for linear regression
	var x = var.reading
	var y = var.targetPosition
	set var.Sx = var.Sx + var.x
	set var.Sy = var.Sy + var.y
	set var.Sxx = var.Sxx + var.x * var.x
	set var.Sxy = var.Sxy + var.x * var.y

	; Increment count of data points
	var count = iterations + 1

	; Perform regression calculations only if we have at least 2 data points
	if var.count >= 2
		; Compute denominator for slope calculation
		var denominator = var.count * var.Sxx - var.Sx * var.Sx

		if var.denominator == 0
			set var.loopError = 1
			M118 S{"[calibrate_pos_sensor.g] Error: Cannot compute linear regression (denominator is zero)"}
			break

		; Calculate slope (k) and intercept (c)
		var k = (var.count * var.Sxy - var.Sx * var.Sy) / var.denominator
		var c = (var.Sy - var.k * var.Sx) / var.count
		; Predict position using current regression parameters
		var predictedPosition = var.k * var.reading + var.c
		var diff = abs(var.predictedPosition - var.targetPosition)

		M118 S{"[calibrate_pos_sensor.g] Position:"^ var.targetPosition ^ ", Predicted:" ^ var.predictedPosition ^ ", Deviation: " ^ var.diff}

M400

if var.loopError == 1
	; move tool to a safe position after calibration and set the axis minimum to a safe value
	if var.TOOL == 0
		G1 U{var.SAFE_UW_MINIMUM} F1000
		M400
		M208 U{var.SAFE_UW_MINIMUM} S1
	else
		G1 W{var.SAFE_UW_MINIMUM} F1000
		M400
		M208 W{var.SAFE_UW_MINIMUM} S1
	M400
	M98 P"/macros/assert/abort.g" Y{"T%s touch sensor calibration failed. Please retry or contact customer support"} A{param.T,} F{var.CURRENT_FILE} E16440
M400

; Calculate final regression parameters
; Compute denominator for slope calculation
var denominator = var.n * var.Sxx - var.Sx * var.Sx

if var.denominator == 0
	M118 S{"[calibrate_pos_sensor.g] Error: Cannot compute final linear regression (denominator is zero)"}
	M98 P"/macros/assert/abort.g" Y{"T%s's touch sensor calibration failed"} A{param.T,} F{var.CURRENT_FILE} E16442

; Calculate final slope (k) and intercept (c)
var k = (var.n * var.Sxy - var.Sx * var.Sy) / var.denominator
var c = (var.Sy - var.k * var.Sx) / var.n

; Compute B and C parameters for M308
var B_PARAM = var.c
var C_PARAM = var.k * var.ADC_FULL_SCALE + var.B_PARAM

; move back down in steps to verify calibration
var mean_deviation = 0
M118 S{"[calibrate_pos_sensor.g] Verifying calibration"}
while iterations < var.n
	; Move tool axis to sample point from last to first
	var targetPosition = var.POINTS[var.n - 1 - iterations]
	if var.TOOL == 0
		G1 U{var.targetPosition} F1000
	else
		G1 W{var.targetPosition} F1000
	M400
	G4 S2
	M400
	; Read sensor value
	var reading = 0
	while iterations < var.NUM_SAMPLES
		set var.reading = var.reading + sensors.analog[var.SENSOR_ID].lastReading
		G4 P{var.SAMPLE_MS}
	M400
	set var.reading = var.reading / var.NUM_SAMPLES

	var measuredPosition = var.k * var.reading + var.c
	var diff = abs(var.measuredPosition - var.targetPosition)
	set var.mean_deviation = var.mean_deviation + var.diff
	M118 S{"[calibrate_pos_sensor.g] Position:"^ var.targetPosition ^ ", Measured:" ^ var.measuredPosition ^ ", Deviation: " ^ var.diff}
	M400
	if var.diff > var.CALIB_THRESHOLD
		M118 S{"[calibrate_pos_sensor.g] Error: Calibration verification failed"}
		set var.loopError = 2
	M400
M400

; move tool to a safe position after calibration and set the axis minimum to a safe value
if var.TOOL == 0
	G1 U{var.SAFE_UW_MINIMUM} F1000
	M400
	M208 U{var.SAFE_UW_MINIMUM} S1
else
	G1 W{var.SAFE_UW_MINIMUM} F1000
	M400
	M208 W{var.SAFE_UW_MINIMUM} S1
M400

if var.loopError == 2
	M98 P"/macros/assert/abort.g" Y{"T%s's touch sensor calibration verification failed"} A{param.T,} F{var.CURRENT_FILE} E16443
M400

set var.mean_deviation = var.mean_deviation/var.n

; Save the calibration parameters to persistent variable
set global.touchBedSensorParams[var.TOOL] = {var.B_PARAM, var.C_PARAM}
M98 P"/macros/variable/save_number.g" N"global.touchBedSensorParams" V{global.touchBedSensorParams}

M98 P"/macros/report/event.g" Y{"T%s touch sensor calibration successful with a mean deviation of %smm. Please restart the machine."}  A{param.T,var.mean_deviation} F{var.CURRENT_FILE} V16443

; Configure the calibrated sensor
M308 S{var.SENSOR_ID} P{"70.hall"^var.TOOL} Y"linear-analog" B{var.B_PARAM} C{var.C_PARAM} F1 A{"touch_t"^var.TOOL^"[mm]"}
G4 S1
M400

M118 S{"[calibrate_pos_sensor.g] Computed parameters: Slope (k) = " ^ var.k ^ ", Intercept (c) = " ^ var.c}
M118 S{"[calibrate_pos_sensor.g] Configured sensor " ^ var.SENSOR_ID ^ " with B = " ^ var.B_PARAM ^ ", C = " ^ var.C_PARAM}
; -----------------------------------------------------------------------------
M118 S{"[calibrate_pos_sensor.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
