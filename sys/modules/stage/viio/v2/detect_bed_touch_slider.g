; -----------------------------------------------------------------------------
; Description:
;	This macro is used to detect at what z position the nozzle touches the bed using the linear resistive probe.
;
; Input parameters:
;	- T: Tool to use
;	- (optional) X: Position in X perform the detection. If it is not
;					present a random position in the safe area will be
;					assigned.
;	- (optional) Y: Position in Y perform the detection. If it is not
;					present a random position in the safe area will be
;					assigned.
;	- (optional) D: Debug mode. If it is present and set to 1, we will spit out more messages.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/viio/v2/detect_bed_touch_slider.g"
M118 S{"[detect_bed_touch_slider.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/stage/viio/v2/calibrate_pos_sensor.g"} F{var.CURRENT_FILE} E16550
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.touchBedCalibrations)} Y{"Missing global variable touchBedCalibrations"} F{var.CURRENT_FILE} E16552
M98 P"/macros/assert/abort_if.g" R{#global.touchBedCalibrations<2} Y{"Global variable touchBedCalibrations needs to have length 2"} F{var.CURRENT_FILE} E16553
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing required module STAGE"} F{var.CURRENT_FILE} E16554
M98 P"/macros/assert/abort_if.g" R{!exists(global.TOUCH_BED_SENSOR_IDS)} Y{"Missing global variable TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16556
M98 P"/macros/assert/abort_if.g" R{(!exists(param.T)||(exists(param.T)&&param.T == null))} Y{"Parameter T is missing or it is null"} F{var.CURRENT_FILE} E16557
M98 P"/macros/assert/abort_if.g" R{(param.T>2||param.T<0)} Y{"Parameter T out of range"} F{var.CURRENT_FILE} E16558
M98 P"/macros/assert/abort_if.g" R{(#global.TOUCH_BED_SENSOR_IDS<=param.T)} Y{"Not valid index to access TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16559
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T].active[0]))} Y{"Missing tool configuration"} F{var.CURRENT_FILE} E16560

G90 ; absolute
; Definitions -----------------------------------------------------------------
; [mm] Random position in X and Y in the safe are to perform the bedtouch.
var X_RANDOM 				= move.axes[0].min + random(floor(abs(move.axes[0].min)))
var Y_RANDOM 				= 50 + random(50)

; Input Parameters
var TOOL					= param.T
var DEBUG					= (exists(param.D) && param.D == 1) ? true : false ; Debug mode
var LOG  					= (exists(param.L) && param.L == 0) ? false : true ; Whether to log to CSV file
var INCLUDE_HEADERS			= (exists(param.H) && param.H == 1) ? true : false ; Whether to include headers in the CSV file
var LOGFILE					= (exists(param.F) && param.F != null) ? param.F : "/sys/logs/stage/bedtouch_probe_offsets.csv"
var X_POSITION				= (exists(param.X) && param.X != null) ? param.X : var.X_RANDOM ; Position in X to perform the detection, random if not provided
var Y_POSITION				= (exists(param.Y) && param.Y != null) ? param.Y : var.Y_RANDOM ; Position in Y to perform the detection, random if not provided
var PROBE_OFFSET			= (exists(param.O) && param.O != null) ? param.O : 0 ; [mm] only used for log output
var SENSOR_ID				= global.TOUCH_BED_SENSOR_IDS[var.TOOL]  ; Sensor to use

var FAST_MOVE_SPEED			= 7000	; [mm/min] Speed used for fast moves
var PROBE_START_Z			= { (exists(param.Z) && param.Z != null) ? param.Z : 5}		; [mm] Z position to start probing with the nozzle, needs to be always above the bed for any UW position
var PROBE_START_UW			= global.TOUCH_BED_VALID_RANGE[0]							; [mm] Target UW position where we should find the bed
var UW_SAFE_POS				= move.axes[3+var.TOOL].max - 5								; [mm] Safe position to move the tool after the detection
var STEP_SIZE 				= 0.2	; [mm] step size to move down
var TOUCH_THRESHOLD 		= 0.15	; [mm] threshold to detect the bed
var BACKLASH 				= global.touchBedSensorBacklash[var.TOOL] == null ? 0 : global.touchBedSensorBacklash[var.TOOL] ; [mm] backlash of the system (distance before the sensor change kicks in when moving down)
var MIN_Z					= -1 ; [mm] minimum position to move down in Z before we fail

var SAMPLE_MS 				= 500 ; [ms] time to wait between samples

; --------------------------------------------------------------------------
; prepare tool axis
; --------------------------------------------------------------------------

if var.DEBUG
	M118 S{"[detect_bed_touch_slider.g] Probing T"^var.TOOL^" at X="^var.X_POSITION^" Y="^var.Y_POSITION}
M400
; Deselect the tool
T-1
M400

; move to the position where we want to probe
G1 Z{var.PROBE_START_Z} F{var.FAST_MOVE_SPEED}
M400

T{var.TOOL}
M400

G1 X{var.X_POSITION} Y{var.Y_POSITION} F{var.FAST_MOVE_SPEED}
M400
; reset tool axis minimum to 0 and move down to start position. Check position sensor to see if we are at the correct position
; if the axis gets stuck when moving down, we will abort
if(var.TOOL == 0)
	M208 U0 S1
	M400
	G1 U{var.PROBE_START_UW} F{var.FAST_MOVE_SPEED}
elif(var.TOOL == 1)
	M208 W0 S1
	M400
	G1 W{var.PROBE_START_UW} F{var.FAST_MOVE_SPEED}
M400

G4 S0.5
M400
var UWSensorPosition = sensors.analog[var.SENSOR_ID].lastReading
var UWPositionDiff = move.axes[3+var.TOOL].userPosition - var.UWSensorPosition
M118 S{"[detect_bed_touch_slider.g] Initial position diff: "^var.UWPositionDiff}
if abs(var.UWPositionDiff) > var.TOUCH_THRESHOLD
	T-1
	M400
	M98 P"/macros/assert/abort.g" Y{"T%s did not reach target position when moving down. Check lifting motor and sliders"} A{var.TOOL,} F{var.CURRENT_FILE} E16561
M400

if var.DEBUG
	M118 S{"[detect_bed_touch_slider.g] Moving down..."}

var UWBedPosition = var.PROBE_START_UW
var touchDepth = 0
var bedSensorValue = 0
; --------------------------------------------------------------------------
; Main loop
; --------------------------------------------------------------------------
M118 S{"[detect_bed_touch_slider.g] UW Start Position: "^var.PROBE_START_UW}
G91 ; relative
var loopError = 0
while true
	; backup in case anything goes wrong
	if (move.axes[2].userPosition <= var.MIN_Z)
		set var.loopError = 1
		break
	M400
	; move down with step size
	G1 Z{-var.STEP_SIZE} F{var.FAST_MOVE_SPEED}
	M400

	; read the sensor value and check if touched bed
	var sensorDiff = abs(sensors.analog[var.SENSOR_ID].lastReading - var.PROBE_START_UW)
	if (var.sensorDiff > var.TOUCH_THRESHOLD)
		; ------------------------------
		; we reached the bed, calculate offset
		; ------------------------------
		; take out the Z spindle backlash
		G1 Z-0.2 F{var.FAST_MOVE_SPEED}
		G1 Z0.2 F{var.FAST_MOVE_SPEED}
		M400
		if var.DEBUG
			M118 S{"[detect_bed_touch_slider.g] Bed reached at Z="^move.axes[2].userPosition^"mm"}

		; we wait at least for a few more samples so that the sensor value is stable
		G4 S1
		M400
		set var.bedSensorValue = sensors.analog[var.SENSOR_ID].lastReading
		M118 S{"[detect_bed_touch_slider.g] Sensor value at bed: "^var.bedSensorValue}
		set var.touchDepth = var.bedSensorValue - var.PROBE_START_UW
		M118 S{"[detect_bed_touch_slider.g] Touch depth: "^var.touchDepth}
		set var.UWBedPosition = move.axes[3+var.TOOL].userPosition + var.touchDepth + move.axes[2].userPosition

		; check whether the offset is within a reasonable range, based on the step size
		var OUT_OF_RANGE = var.UWBedPosition < global.TOUCH_BED_VALID_RANGE[0] || var.UWBedPosition > global.TOUCH_BED_VALID_RANGE[1]
		if var.OUT_OF_RANGE
			set var.loopError = 2
		break
	M400
M400

G90 ; absolute

T-1
M400

; move up in Z if necessary so that extruder can be selected
if (move.axes[2].userPosition < 0)
	G1 Z0 F{var.FAST_MOVE_SPEED}
M400

; Log output to csv file and console so it appears in the print report
var HEADERS = "TOOL,SENSOR_B,SENSOR_C,BACKLASH,x_pos,y_pos,measured_z_pos,measured_probe_offset,measured_bed_sens_value,measured_touch_depth,measured_uw_pos,error"
var PART1 = {var.TOOL}^","^{global.touchBedSensorParams[var.TOOL][0]}^","^{global.touchBedSensorParams[var.TOOL][1]}^","^{var.BACKLASH}^","^{var.X_POSITION}^","^{var.Y_POSITION}^","^move.axes[2].userPosition^","
var PART2 = {var.PROBE_OFFSET}^","^{var.bedSensorValue}^","^{var.touchDepth}^","^{var.UWBedPosition}^","^{var.loopError}
if var.LOG
	if var.INCLUDE_HEADERS
		echo >{var.LOGFILE} {var.HEADERS}
	M400
	echo >>{var.LOGFILE} {var.PART1^var.PART2}
M400

if var.loopError > 0
	; calibration did not work, set axis minimum to safe position and throw error
	if(var.TOOL == 0)
		M208 U{var.UW_SAFE_POS} S1
	elif(var.TOOL == 1)
		M208 W{var.UW_SAFE_POS} S1
	M400
	; throw appropriate error messages
	if var.loopError == 1
		M98 P"/macros/assert/abort.g" Y{"T"^var.TOOL^" Could not find bed but reached Z minimum "^var.MIN_Z}  F{var.CURRENT_FILE} E16563
	elif var.loopError == 2
		var tooLow = var.UWBedPosition < global.TOUCH_BED_VALID_RANGE[0]
		if var.tooLow
			M98 P"/macros/assert/abort.g" Y{"Ball sensor is too low! T%s's bed position out of range: %smm"} A{var.TOOL,var.UWBedPosition}  F{var.CURRENT_FILE} E16564
		else
			M98 P"/macros/assert/abort.g" Y{"Ball sensor is too high! T%s's bed position out of range: %smm"} A{var.TOOL,var.UWBedPosition} F{var.CURRENT_FILE} E16565
		M400
	M400
M400


M118 S{"[detect_bed_touch_slider.g]csv_headers="^var.HEADERS}
M118 S{"[detect_bed_touch_slider.g]csv_data="^var.PART1^var.PART2}

;apply offsets
set var.UWBedPosition = var.UWBedPosition + var.BACKLASH

; save the print position touch sensor values
set global.touchBedCalibrations[var.TOOL] = var.UWBedPosition

M118 S{"[detect_bed_touch_slider.g] T"^var.TOOL^" UW Bed position: "^var.UWBedPosition^"mm"}
M118 S{"[detect_bed_touch_slider.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit