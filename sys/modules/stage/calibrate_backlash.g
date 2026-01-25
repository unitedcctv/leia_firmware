; -----------------------------------------------------------------------------
; Description:
;	@TODO
;
; Input parameters:
;	- T: Tool to use
;	- (optional) X: Position in X perform the detection. If it is not
;					present a random position in the safe area will be
;					assigned.
;	- (optional) Y: Position in Y perform the detection. If it is not
;					present a random position in the safe area will be
;					assigned.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/calibrate_backlash.g"
M118 S{"[calibrate_backlash.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing required module STAGE"} F{var.CURRENT_FILE} E16700
M98 P"/macros/assert/abort_if.g" R{!exists(global.TOUCH_BED_SENSOR_IDS)} Y{"Missing global variable TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16701
M98 P"/macros/assert/abort_if.g" R{(!exists(param.T)||(exists(param.T)&&param.T == null))} Y{"Parameter T is missing or it is null"} F{var.CURRENT_FILE} E16702
M98 P"/macros/assert/abort_if.g" R{(param.T>1||param.T<0)} Y{"Parameter T out of range"} F{var.CURRENT_FILE} E16703
M98 P"/macros/assert/abort_if.g" R{(#global.TOUCH_BED_SENSOR_IDS<=param.T)} Y{"Not valid index to access TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16704
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T].active[0]))} Y{"T%s is not connected"} A{param.T,} F{var.CURRENT_FILE} E16705

G90 ; absolute
; Definitions -----------------------------------------------------------------
; [mm] Middle of the portal, so that the Z backlash is averaged from all spindles
var X_DEFAULT 				= (move.axes[0].max - move.axes[0].min) / 2
var Y_DEFAULT				= (move.axes[1].max - move.axes[1].min) / 2

; Input Parameters
var TOOL					= param.T
var X_POSITION				= (exists(param.X) && param.X != null) ? param.X : var.X_DEFAULT ; Position in X to perform the detection, random if not provided
var Y_POSITION				= (exists(param.Y) && param.Y != null) ? param.Y : var.Y_DEFAULT ; Position in Y to perform the detection, random if not provided
var SENSOR_ID				= global.TOUCH_BED_SENSOR_IDS[var.TOOL]  ; Sensor to use

var FAST_MOVE_SPEED			= 7000	; [mm/min] Speed used for fast moves
var PROBE_START_Z			= { (exists(param.Z) && param.Z != null) ? param.Z : 5}		; [mm] Z position to start probing with the nozzle, needs to be always above the bed for any UW position
var PROBE_START_UW			= global.TOUCH_BED_VALID_RANGE[0]							; [mm] Target UW position where we should find the bed
var UW_SAFE_POS				= move.axes[3+var.TOOL].max - 5								; [mm] Safe position to move the tool after the detection
var STEP_SIZE 				= 0.1	; [mm] step size to move down
var TOUCH_THRESHOLD 		= 0.3	; [mm] threshold to detect the bed
var MIN_Z					= -1 ; [mm] minimum position to move down in Z before we fail

var NUM_SAMPLES = 7					; number of samples to take for the average
var SAMPLE_MS 				= 500 ; [ms] time to wait between samples

var Z_OVERSTEP				= 0.5 ; [mm] distance to move down and up to take out the backlash
var MAX_CUMULATIVE_BACKLASH = 0.2 ; [mm] maximum cumulative backlash allowed
var SAVE				= exists(param.S) ? param.S : 1 ; [0/1] save the number in the global variable

; --------------------------------------------------------------------------
; prepare tool axis
; --------------------------------------------------------------------------

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
M118 S{"[calibrate_backlash.g] Initial position diff: "^var.UWPositionDiff}
if abs(var.UWPositionDiff) > var.TOUCH_THRESHOLD
	T-1
	M400
	M98 P"/macros/assert/abort.g" Y{"T%s did not reach target position when moving down. Check lifting motor and sliders"} A{var.TOOL,} F{var.CURRENT_FILE} E16706
M400

var UWBedPosition = var.PROBE_START_UW
var touchDepth = 0
var bedSensorValue = 0
var bedSensorValuePreBacklash = 0
var zBacklash = 0

; --------------------------------------------------------------------------
; Main loop
; --------------------------------------------------------------------------
M118 S{"[calibrate_backlash.g] UW Start Position: "^var.PROBE_START_UW}
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
		; we reached the bed, now we need to check the backlash
		; first we need to get the average sensor value at the bed
		G4 S1
		while iterations < var.NUM_SAMPLES
			set var.bedSensorValuePreBacklash = var.bedSensorValuePreBacklash + sensors.analog[var.SENSOR_ID].lastReading
			G4 P{var.SAMPLE_MS}
		M400
		set var.bedSensorValuePreBacklash = var.bedSensorValuePreBacklash / var.NUM_SAMPLES
		M118 S{"[calibrate_backlash.g] Bed Sensor Value Pre Backlash: "^var.bedSensorValuePreBacklash}
		; take out the backlash by moving down and up
		G1 Z{-var.Z_OVERSTEP} F300
		M400
		G1 Z{var.Z_OVERSTEP} F300
		M400
		; we wait at least for a few more samples so that the sensor value is stable

		G4 S1
		M400
		while iterations < var.NUM_SAMPLES
			set var.bedSensorValue = var.bedSensorValue + sensors.analog[var.SENSOR_ID].lastReading
			G4 P{var.SAMPLE_MS}
		M400
		set var.bedSensorValue = var.bedSensorValue / var.NUM_SAMPLES
		M118 S{"[calibrate_backlash.g] Bed Sensor Value: "^var.bedSensorValue}

		set var.zBacklash = var.bedSensorValue - var.bedSensorValuePreBacklash
		M118 S{"[calibrate_backlash.g] Z backlash: "^var.zBacklash}

		set var.touchDepth = var.bedSensorValue - var.PROBE_START_UW
		M118 S{"[calibrate_backlash.g] Touch depth: "^var.touchDepth}

		if var.touchDepth < 0
			; touch depth is negative, something went wrong
			set var.loopError = 2
			break

		set var.UWBedPosition = move.axes[3+var.TOOL].userPosition + var.touchDepth + move.axes[2].userPosition

		; check whether the offset is within a reasonable range, based on the step size
		var OUT_OF_RANGE = var.UWBedPosition < global.TOUCH_BED_VALID_RANGE[0] || var.UWBedPosition > global.TOUCH_BED_VALID_RANGE[1]
		if var.OUT_OF_RANGE
			set var.loopError = 3
			break

		break ; success
	M400
M400

if var.loopError > 0
	; calibration did not work, set axis minimum to safe position and throw error
	G90 ; absolute
	if(var.TOOL == 0)
		M208 U{var.UW_SAFE_POS} S1
	elif(var.TOOL == 1)
		M208 W{var.UW_SAFE_POS} S1
	M400
	; throw appropriate error messages
	if var.loopError == 1
		M98 P"/macros/assert/abort.g" Y{"T%s Could not find bed but reached Z minimum %s. Ensure Tool is mounted properly and check Lifting system"} A{var.TOOL, var.MIN_Z} F{var.CURRENT_FILE} E16707
	elif var.loopError == 2
		M98 P"/macros/assert/abort.g" Y{"T%s Touch depth is negative: %smm. Check Lifting system"}  F{var.CURRENT_FILE} E16708
	elif var.loopError == 3
		var tooLow = var.UWBedPosition < global.TOUCH_BED_VALID_RANGE[0]
		if var.tooLow
			M98 P"/macros/assert/abort.g" Y{"T%s bed position out of range: %smm. Check Lifting system"} A{var.TOOL,var.UWBedPosition}  F{var.CURRENT_FILE} E16709
		else
			M98 P"/macros/assert/abort.g" Y{"Check Lifters! T%s's bed position out of range: %smm. Check Lifting system"} A{var.TOOL,var.UWBedPosition} F{var.CURRENT_FILE} E16710
		M400
	M400
M400

; check value on bed
; move up so we are theoretically at the border between bed and air, but in fact lower due to backlash of extruder assembly
G1 Z{var.touchDepth} F{var.FAST_MOVE_SPEED}
M400
G4 S1
M400
;============================================
; check value on bed

set var.bedSensorValue = 0
while iterations < var.NUM_SAMPLES
	set var.bedSensorValue = var.bedSensorValue + sensors.analog[var.SENSOR_ID].lastReading
	G4 P{var.SAMPLE_MS}
M400
set var.bedSensorValue = var.bedSensorValue / var.NUM_SAMPLES
M118 S{"[calibrate_backlash.g] Bed Sensor Value: "^var.bedSensorValue}

; move up so we float above the bed
G1 Z{var.touchDepth} F{var.FAST_MOVE_SPEED}
M400

;============================================
; check value in the air

G4 S1
M400
var airSensorValue = 0
while iterations < var.NUM_SAMPLES
	set var.airSensorValue = var.airSensorValue + sensors.analog[var.SENSOR_ID].lastReading
	G4 P{var.SAMPLE_MS}
M400
set var.airSensorValue = var.airSensorValue / var.NUM_SAMPLES
M118 S{"[calibrate_backlash.g] Air Sensor Value: "^var.airSensorValue}

; ============================================
; determine backlash of extruder assembly
var backlash = var.bedSensorValue - var.airSensorValue
M118 S{"[calibrate_backlash.g] Tool Backlash: "^var.backlash}
M118 S{"[calibrate_backlash.g] Z Backlash: "^var.zBacklash}

var overallBacklash = var.backlash + var.zBacklash
M118 S{"[calibrate_backlash.g] Cumulative Backlash: "^var.overallBacklash}

; check that backlash is positive
M98 P"/macros/assert/abort_if.g" R{var.overallBacklash < 0} Y{"T%s Cumulative Backlash is negative: %s mm. Check Lifting system"} A{var.TOOL, var.backlash} F{var.CURRENT_FILE} E16711
; check backlash value is within limits
M98 P"/macros/assert/abort_if.g" R{var.overallBacklash > var.MAX_CUMULATIVE_BACKLASH} Y{"T% Backlash is too high: %s mm. Check Lifting system"} A{var.TOOL, var.backlash} F{var.CURRENT_FILE} E16712


; set value for current tool position as determined in this calibration
set var.UWBedPosition = var.UWBedPosition + var.overallBacklash

; set value for further calibrations
if var.SAVE == 1
	set global.touchBedSensorBacklash[var.TOOL] = var.overallBacklash
	M98 P"/macros/variable/save_number.g" N"global.touchBedSensorBacklash" V{global.touchBedSensorBacklash}
M400

G90 ; absolute
; go back to start in Z
G1 Z{var.PROBE_START_Z} F{var.FAST_MOVE_SPEED}

; move tool up and reset Tool axis minimum
if(var.TOOL == 0)
	G1 U{move.axes[3].max + 5} H1 F1000
	M400
	M208 U{var.UWBedPosition} S1
elif(var.TOOL == 1)
	G1 W{move.axes[4].max + 5} H1 F1000
	M400
	M208 W{var.UWBedPosition} S1
M400

; ensure tool is deselected
T-1

; send finish event
M98 P"/macros/report/event.g" Y{"Calibration successful. Backlash for T%s: %s mm"} A{var.TOOL, var.overallBacklash} F{var.CURRENT_FILE} V16713

M118 S{"[calibrate_backlash.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit