; Description:
;	This macro determines the sensor type for the bed touch detection and
;	calls the according submacro to perform the detection.
;
; Input parameters:
;	- T: Tool to use
;	- (optional) X: Position in X perform the detection. If it is not
;					present a random position in the safe are will be
;					assigned.
;	- (optional) Y: Position in Y perform the detection. If it is not
;					present a random position in the safe are will be
;					assigned.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/viio/v2/detect_bed_touch.g"
M118 S{"[detect_bed_touch.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/stage/viio/v2/detect_bed_touch_slider.g"} F{var.CURRENT_FILE} E16460
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/stage/viio/v2/detect_bed_touch_hall.g"} F{var.CURRENT_FILE} E16462
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{(!exists(param.T)||(exists(param.T)&&param.T == null))} Y{"Parameter T is missing or it is null"} F{var.CURRENT_FILE} E16469
M98 P"/macros/assert/abort_if.g" R{(param.T>2||param.T<0)} Y{"Parameter T out of range"} F{var.CURRENT_FILE} E16470
M98 P"/macros/assert/abort_if.g" R{(#global.TOUCH_BED_SENSOR_IDS<=param.T)} Y{"Not valid index to access TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16471
M98 P"/macros/assert/abort_if.g" R{global.touchBedSensorBacklash[param.T] == null} Y{"Missing Calibration: Please run T%s Backlash Calibration in Maintenance menu"} A{param.T,} F{var.CURRENT_FILE} E16473

var TOOL 					= param.T
var SENSOR_ID 				= global.TOUCH_BED_SENSOR_IDS[var.TOOL]  ; Sensor to use
var SLIDER_SENSOR_THRESHOLD = 3000 ; [mV] Threshold to determine the sensor type. Higher than threshold is slider sensor
var NOT_CONNECTED_THRESHOLD_HALL = 100 ; [mV] Threshold to determine whether a sensor is connected, Lower means not connected
var NOT_CONNECTED_THRESHOLD_LINEAR = 0.1 ; [mm] Threshold to determine whether a sensor is connected, Lower means not connected
var FAST_MOVE_SPEED			= 10000
; Checking the input parameters -----------------------------------------------
var X_RANDOM 				= move.axes[0].min + random(floor(abs(move.axes[0].min)))
var Y_RANDOM 				= 50 + random(50)
var X_POSITION 				= (exists(param.X) && param.X != null) ? param.X : var.X_RANDOM
var Y_POSITION 				= (exists(param.Y) && param.Y != null) ? param.Y : var.Y_RANDOM
var Z_POSITION_TOUCH_START_HALL 	= 5 ; [mm] Z position to start probing with the hall sensor
var Z_POSITION_TOUCH_START_LINEAR 	= 3 ; [mm] Z position to start probing with the linear sensor
var Z_POSITION_PROBE_START  = 0				; [mm] Where to start probing with the probe (ball-sensor)
var NUM_PROBES				= (exists(param.B) && param.B != null) ? param.B : 3 ; How often to probe before doing nozzle touch detection
var PROBE_REPEAT_DISTANCE 	= 5 ; [mm] Distance to move between probe attempts
var PROBE_OFFSET_THRESHOLD  = 0.2 ; [mm] Threshold to successfully probe before doing nozzle touch detection. If outside, there might be some dirt on the bed
var WIPE					= (exists(param.W) && param.W == 0) ? false : true ; Whether to wipe the nozzle before the touch detection

; only wipe if wanted and wiper is activated
set var.WIPE = var.WIPE && exists(global.wiperPresent) && global.wiperPresent

var UW_VALID_PRINT_POS = global.TOUCH_BED_VALID_RANGE ; {minimum_allowed_value , maximum_allowed_value}

var INCLUDE_HEADERS			= (exists(param.H) && param.H == 1) ? 1 : 0 ; Whether to include headers in the CSV file
var LOGFILE					= (exists(param.F) && param.F != null) ? param.F : "/sys/logs/stage/bedtouch_probe_offsets.csv"



; Deselect the tool
T-1
M400

; --------------------------------------------------------------------------------------------
; Detect sensor type and connection
; --------------------------------------------------------------------------------------------
var LINEAR_SENSOR_INSTALLED = global.touchLinearInstalled[var.TOOL]

; if linear sensor is not preconfigured, we might a have non-calibrated one, so we check the hall threshold
var SENSOR_CONNECTED = false
if var.LINEAR_SENSOR_INSTALLED
	set var.SENSOR_CONNECTED = sensors.analog[var.SENSOR_ID].lastReading > var.NOT_CONNECTED_THRESHOLD_LINEAR
else
	set var.SENSOR_CONNECTED = sensors.analog[var.SENSOR_ID].lastReading > var.NOT_CONNECTED_THRESHOLD_HALL
	; if we have have a potentially uncalibrated linear sensor, we will find out here
	set var.LINEAR_SENSOR_INSTALLED = sensors.analog[var.SENSOR_ID].lastReading > var.SLIDER_SENSOR_THRESHOLD

set global.touchLinearInstalled[var.TOOL] = var.LINEAR_SENSOR_INSTALLED

M98 P"/macros/assert/abort_if.g" R{!var.SENSOR_CONNECTED} Y{"T%s touch sensor disconnected. Please check wiring!"} A{var.TOOL,} F{var.CURRENT_FILE} E16472

if (!exists(global.touchSensorPrintPosValues))
	global touchSensorPrintPosValues = {null,null}

; threshold to use for obstacle detection. It can be different per sensor type
if (!exists(global.touchSensorObstacleThresholds))
	global touchSensorObstacleThresholds = {null,null}

; check if sensor was calibrated previously. If not, do it
if var.LINEAR_SENSOR_INSTALLED
	var needCalib = global.touchBedSensorParams[var.TOOL] == null || global.touchBedSensorParams[var.TOOL][0] == null || global.touchBedSensorParams[var.TOOL][1] == null
	if var.needCalib
		; move z to a safe position
		if (!move.axes[2].homed || move.axes[2].machinePosition < 20)
			G91
			G1 H1 Z20
			G90
		M400
		M98 P"/sys/modules/stage/viio/v2/calibrate_pos_sensor.g" T{var.TOOL}
		M400
		T-1
	M400
M400


; --------------------------------------------------------------------------------------------
; Probe first and store the offset
; --------------------------------------------------------------------------------------------
var finalProbeOffset = 0
var finalProbeYpos = var.Y_POSITION
if var.NUM_PROBES > 0
	var probeOffsets = vector(var.NUM_PROBES, 0)
	while iterations < var.NUM_PROBES
		; Moving down with the probe and measure the distance to the bed --------------
		G1 Z{var.Z_POSITION_PROBE_START} F{var.FAST_MOVE_SPEED}
		G1 X{var.X_POSITION} Y{var.Y_POSITION + iterations * var.PROBE_REPEAT_DISTANCE}
		G1 Z{global.PROBE_OFFSET_Z-0.2}
		G1 Z{global.PROBE_OFFSET_Z}
		M400
		G4 S0.2
		M400
		M98 P"/macros/probe/get_sample_single_z.g"
		M400
		M98 P"/macros/assert/abort_if_null.g" R{global.probeMeasuredValue} Y"Unable to get the samples with the probe" F{var.CURRENT_FILE} E16633
		M400
		set var.probeOffsets[iterations] = global.probeMeasuredValue
		M118 S{"[detect_bed_touch.g] T"^var.TOOL^" Probe offset "^ (iterations+1) ^": "^var.probeOffsets[iterations]}
	M400

	; use the smallest offset as the final offset
	while iterations < #var.probeOffsets
		if (iterations == 0) || (abs(var.probeOffsets[iterations]) < abs(var.finalProbeOffset))
			set var.finalProbeYpos = var.Y_POSITION + iterations * var.PROBE_REPEAT_DISTANCE
			set var.finalProbeOffset = var.probeOffsets[iterations]

	M118 S{"[detect_bed_touch.g] Final probe offset: "^var.finalProbeOffset}
	if abs(var.finalProbeOffset) > var.PROBE_OFFSET_THRESHOLD
		G1 Z{var.Z_POSITION_PROBE_START} F{var.FAST_MOVE_SPEED}
		M98 P"/macros/assert/abort.g" Y{"T%s probe offset is too high. Ensure printbed is clean and level and ball sensor is not damaged. Offset: %s"} A{var.TOOL,var.finalProbeOffset} F{var.CURRENT_FILE} E16638
else
	M118 S{"[detect_bed_touch.g] Probing skipped"}
M400

var Z_POS_TOUCH_START = var.LINEAR_SENSOR_INSTALLED ? var.Z_POSITION_TOUCH_START_LINEAR : var.Z_POSITION_TOUCH_START_HALL
G1 Z{var.Z_POS_TOUCH_START} F{var.FAST_MOVE_SPEED}

; optional wipe if wiper is installed
if(var.WIPE)
	var PARK_Y = var.TOOL == 0 ? move.axes[1].min : move.axes[1].max
	G1 X0 Y{var.PARK_Y} F{var.FAST_MOVE_SPEED}
	M116 P{var.TOOL} S5; wait for the tool to reach temperature
	M98 P"/macros/nozzle_cleaner/wipe.g" T{var.TOOL} F0
else
	M116 P{var.TOOL} S5; wait for the tool to reach temperature
M400

; --------------------------------------------------------------------------------------------
; Run bed touch detection based on installed sensor type
; --------------------------------------------------------------------------------------------

if var.LINEAR_SENSOR_INSTALLED
	set global.touchBedObstacleThresholds[var.TOOL] = 1.5
	M98 P"/sys/modules/stage/viio/v2/detect_bed_touch_slider.g" T{var.TOOL} X{var.X_POSITION} Y{var.finalProbeYpos} Z{var.Z_POSITION_TOUCH_START_LINEAR} O{var.finalProbeOffset} H{var.INCLUDE_HEADERS} F{var.LOGFILE}
else
    set global.touchBedObstacleThresholds[var.TOOL] = 200
    M98 P"/sys/modules/stage/viio/v2/detect_bed_touch_hall.g" T{var.TOOL} X{var.X_POSITION} Y{var.finalProbeYpos} Z{var.Z_POSITION_TOUCH_START_HALL} O{var.finalProbeOffset}
M400
M598

; --------------------------------------------------------------------------------------------
; Apply probe offset to calibrated value
; --------------------------------------------------------------------------------------------

set global.touchBedCalibrations[var.TOOL] = global.touchBedCalibrations[var.TOOL] + var.finalProbeOffset

M118 S{"[detect_bed_touch.g] T"^var.TOOL^" UW bed position: "^global.touchBedCalibrations[var.TOOL]}
; Check for the u and w min pos values
if(global.touchBedCalibrations[var.TOOL] < var.UW_VALID_PRINT_POS[0] || global.touchBedCalibrations[var.TOOL] > var.UW_VALID_PRINT_POS[1])
	M98 P"/macros/report/warning.g" Y{"T%s's calibrated position %s is outside of valid range %s - %s"} A{var.TOOL,global.touchBedCalibrations[var.TOOL],var.UW_VALID_PRINT_POS[0],var.UW_VALID_PRINT_POS[1]} F{var.CURRENT_FILE} W16637

; save the calibration value as minimum value of the UW axes
if(var.TOOL == 0)
	M208 U{global.touchBedCalibrations[var.TOOL]} S1
	M400
elif(var.TOOL == 1)
	M208 W{global.touchBedCalibrations[var.TOOL]} S1
	M400
M400

G1 Z{var.Z_POS_TOUCH_START} F{var.FAST_MOVE_SPEED}
M400
; reselect tool
T{var.TOOL}
M400

; save baseline value after moving to print position
set global.touchSensorPrintPosValues[var.TOOL] = sensors.analog[var.SENSOR_ID].lastReading

; override the touch calibs at job start
if (exists(global.touchBedJobstartValues))
	set global.touchBedJobstartValues = global.touchBedCalibrations
else
	global touchBedJobstartValues = global.touchBedCalibrations

; Persist the calibration values
M98 P"/macros/variable/save_number.g" N"global.touchBedCalibrations" V{global.touchBedCalibrations} C1

M118 S{"[detect_bed_touch.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit