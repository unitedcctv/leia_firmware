; Description:
;	The goal is to move down with the nozzle until the bed it touch and set
;	this value as the default position of the extruder.
; 	NOTE(!): Set the tool temperature before starting the process
;
; Input parameters:
;	- T: Tool to use
;	- (optional) X: Position in X perform the detection. If it is not
;					present a random position in the safe are will be
;					assigned.
;	- (optional) Y: Position in Y perform the detection. If it is not
;					present a random position in the safe are will be
;					assigned.
;
; TODO:
;	- Define a range of MAX_VALUES to check if the calibration
;  	  is out of range.
;	- Save the calibration value? It is a fast value to obtain
;  	  it may not worth it but it can be used to check errors.
;	- Handle better the case that after moving up the sensors is still
;	  in the stop position, in the while.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/viio/v2/detect_bed_touch_hall.g"
M118 S{"[TOUCH T"^param.T^"] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.touchBedCalibrations)} Y{"Missing global variable touchBedCalibrations"} F{var.CURRENT_FILE} E16624
M98 P"/macros/assert/abort_if.g" R{#global.touchBedCalibrations<2} Y{"Global variable touchBedCalibrations needs to have length 2"} F{var.CURRENT_FILE} E16625
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing required module STAGE"} F{var.CURRENT_FILE} E16626
M98 P"/macros/assert/abort_if.g" R{!exists(global.TOUCH_BED_SENSOR_IDS)} Y{"Missing global variable TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16628
M98 P"/macros/assert/abort_if.g" R{(!exists(param.T)||(exists(param.T)&&param.T == null))} Y{"Parameter T is missing or it is null"} F{var.CURRENT_FILE} E16629
M98 P"/macros/assert/abort_if.g" R{(param.T>2||param.T<0)} Y{"Parameter T out of range"} F{var.CURRENT_FILE} E16630
M98 P"/macros/assert/abort_if.g" R{(#global.TOUCH_BED_SENSOR_IDS<=param.T)} Y{"Not valid index to access TOUCH_BED_SENSOR_IDS"} F{var.CURRENT_FILE} E16631
M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T].active[0]))} Y{"Missing tool configuration"} F{var.CURRENT_FILE} E16632


; Definitions -----------------------------------------------------------------
var FAST_MOVE_SPEED			= 7000				; [mm/min] Speed used for fast moves
; [mm] Random position in X and Y in the safe are to perform the bedtouch.
var X_RANDOM 				= move.axes[0].min + random(floor(abs(move.axes[0].min)))
var Y_RANDOM 				= 50 + random(50)
var Z_POSITION_TOUCH_START  = { (exists(param.Z) && param.Z != null) ? param.Z : 5}			; [mm] Where to start proving with the touch sensor (nozzle).
var SENSOR_ID 				= global.TOUCH_BED_SENSOR_IDS[param.T]  ; Sensor to use

; Checking the input parameters -----------------------------------------------
var X_POSITION 			= { (exists(param.X) && param.X != null) ? param.X : var.X_RANDOM}
var Y_POSITION 			= { (exists(param.Y) && param.Y != null) ? param.Y : var.Y_RANDOM}

var UW_START_POSITION 		= { (exists(param.S) && param.S != null) ? param.S : 1.0}
var STEP_SIZE_INITIAL 		= { (exists(param.I) && param.I != null) ? param.I : 0.3}
var STEP_SIZE_FINAL 		= { (exists(param.F) && param.F != null) ? param.F : 0.02}
; if the difference between the calibrated value and the current value is bigger than this value, we know that we have reached the bed
var TOUCH_THRESHOLD 		= { (exists(param.H) && param.H != null) ? param.H : 8.0}
var HANG_THRESHOLD			= { (exists(param.G) && param.G != null) ? param.G : 8.0}
; [mm] backlash of the system
var BACKLASH 				= global.touchBedSensorBacklash[param.T] == null ? 0 : global.touchBedSensorBacklash[param.T] ; [mm] backlash of the system (distance before the sensor change kicks in when moving down)
; number of samples to take when reading sensor
var NUM_SAMPLES 			= { (exists(param.N) && param.N != null) ? param.N : 5}
var SKIP_PROBE				= { (exists(param.K) && param.K == 1) ? true : false}
; absolute minimum for Z axis
var ABS_MINIMUM 			= 0

; we need to wait with our loops where sensor data is read until the sensor has been read at least once
var SAMPLE_MS 				= 255
var timerLap 				= 0
; variable that gets set in loops to check if the step was successful
; if an abort happens in a loop, the system might get stuck so we need to check and abort outside of the loop
var stepOK					= false
; Deselecting the tool --------------------------------------------------------
T-1 ; This will move the extruder up to work with the probe
M400

M118 S{"[TOUCH T"^param.T^"] UW_START_POSITION: "^var.UW_START_POSITION}
M118 S{"[TOUCH T"^param.T^"] STEP_SIZE_INITIAL: "^var.STEP_SIZE_INITIAL}
M118 S{"[TOUCH T"^param.T^"] STEP_SIZE_FINAL: "^var.STEP_SIZE_FINAL}
M118 S{"[TOUCH T"^param.T^"] TOUCH_THRESHOLD: "^var.TOUCH_THRESHOLD}
M118 S{"[TOUCH T"^param.T^"] HANG_THRESHOLD: "^var.HANG_THRESHOLD}
M118 S{"[TOUCH T"^param.T^"] BACKLASH: "^var.BACKLASH}
M118 S{"[TOUCH T"^param.T^"] NUM_SAMPLES: "^var.NUM_SAMPLES}

M598

; Selecting the tool
T{param.T}
; move to the position where we want to measure the sensor -------------------
G1 Z{var.Z_POSITION_TOUCH_START} F{var.FAST_MOVE_SPEED}
M400
; Move tool to the start position
if(param.T == 0)
	; set tool minimum to 0
	M208 U0 S1
	M400
	G1 U{var.UW_START_POSITION} F{var.FAST_MOVE_SPEED}

elif(param.T == 1)
	; set tool minimum to 0
	M208 W0 S1
	M400
	G1 W{var.UW_START_POSITION} F{var.FAST_MOVE_SPEED}

M400

G1 X{var.X_POSITION} Y{var.Y_POSITION} F{var.FAST_MOVE_SPEED}

; --------------------------------------------------------------------------
; calibrate value when the extruder hangs in the air -----------------------
; --------------------------------------------------------------------------

var hangingSensorValue = 0
set var.timerLap = state.upTime*1000+state.msUpTime
while true
	if iterations >= var.NUM_SAMPLES
		break

	; wait at least until the next sample is taken
	var timeDelta = (state.upTime*1000+state.msUpTime) - var.timerLap
	G4 P{(var.timeDelta>var.SAMPLE_MS)?0:(var.SAMPLE_MS-var.timeDelta)}

	set var.hangingSensorValue = var.hangingSensorValue + sensors.analog[var.SENSOR_ID].lastReading
	set var.timerLap = state.upTime*1000+state.msUpTime

set var.hangingSensorValue = var.hangingSensorValue / var.NUM_SAMPLES
M118 S{"[TOUCH T"^param.T^"] Calibration value: "^var.hangingSensorValue}

; --------------------------------------------------------------------------
; Moving down with Z until we are sure that we touched the bed --------------------
; --------------------------------------------------------------------------
M118 S{"[TOUCH T"^param.T^"] Moving down..."}
set var.timerLap = state.upTime*1000+state.msUpTime
while true
	M598
	var time = state.upTime*1000+state.msUpTime
	var newPos = move.axes[2].userPosition - var.STEP_SIZE_INITIAL
	; backup in case anything goes wrong
	if (var.newPos <= var.ABS_MINIMUM)
		T-1
		M118 S{"[TOUCH T"^param.T^"] ERROR: Could not find bed after "^iterations^" iterations"}
		set var.stepOK = false
		break

	G1 Z{var.newPos} F{var.FAST_MOVE_SPEED}

	M400
	; wait at least until the next sample is taken
	var timeDelta = (state.upTime*1000+state.msUpTime) - var.timerLap
	var waitTime = {var.timeDelta>var.SAMPLE_MS?0:(var.SAMPLE_MS-var.timeDelta)}
	G4 P{var.waitTime}

	var sensor_diff = abs(sensors.analog[var.SENSOR_ID].lastReading - var.hangingSensorValue)
	set var.timerLap = state.upTime*1000+state.msUpTime

	if (var.sensor_diff > var.TOUCH_THRESHOLD)
		M118 S{"[TOUCH T"^param.T^"] Bed reached at Z="^var.newPos^"mm"}
		set var.stepOK = true
		break

if (!var.stepOK)
	if(param.T == 0)
		; set tool minimum to safe value
		M208 U{move.axes[3+param.T].max-1} S1

	elif(param.T == 1)
		; set tool minimum to safe value
		M208 W{move.axes[3+param.T].max-1} S1
	M98 P"/macros/assert/abort.g" Y{"T%s calibration failed. Please clean nozzle and try again."} A{param.T,} F{var.CURRENT_FILE} E16635

M400
M598

var onBedPosition = move.axes[2].userPosition

; move off the bed to calibrate the hang value again

G1 Z{var.onBedPosition + 4*var.STEP_SIZE_INITIAL} F{var.FAST_MOVE_SPEED}


M400
; move back in X a bit to get off the poop
G91
G1 X-10 F5000
G90
M400
; --------------------------------------------------------------------------
; calibrate value when the extruder hangs in the air -----------------------
; --------------------------------------------------------------------------
G4 S1
set var.timerLap = state.upTime*1000+state.msUpTime
set var.hangingSensorValue = 0
while true
	if iterations >= var.NUM_SAMPLES
		break

	M598
	; wait at least until the next sample is taken
	var timeDelta = (state.upTime*1000+state.msUpTime) - var.timerLap
	G4 P{(var.timeDelta>var.SAMPLE_MS)?0:(var.SAMPLE_MS-var.timeDelta)}

	set var.hangingSensorValue = var.hangingSensorValue + sensors.analog[var.SENSOR_ID].lastReading
	set var.timerLap = state.upTime*1000+state.msUpTime

set var.hangingSensorValue = var.hangingSensorValue / var.NUM_SAMPLES
M118 S{"[TOUCH T"^param.T^"] Calibration value: "^var.hangingSensorValue}

; move back to the bed
G1 Z{var.onBedPosition} F{var.FAST_MOVE_SPEED}

M400
; --------------------------------------------------------------------------
; moving up in small steps until we are sure that we are not touching the bed anymore
; --------------------------------------------------------------------------
; initialize bed position with safest value = start position
var UWBedPosition = move.axes[3+param.T].max-1

M118 S{"[TOUCH T"^param.T^"] Moving up Z from "^var.onBedPosition}
set var.timerLap = state.upTime*1000+state.msUpTime
set var.stepOK = false
while true
	M598
	var newPos = (move.axes[2].userPosition + var.STEP_SIZE_FINAL)
	; backup in case anything goes wrong
	if (var.newPos >= (var.onBedPosition+var.STEP_SIZE_INITIAL*5))
		M118 S{"[TOUCH T"^param.T^"] ERROR: Could not find bed after "^iterations^" iterations at "^var.newPos}
		set var.stepOK = false
		break

	G1 Z{var.newPos} F{var.FAST_MOVE_SPEED}

	M400

	; wait at least until the next sample is taken
	var timeDelta = (state.upTime*1000+state.msUpTime) - var.timerLap
	var waitTime = {var.timeDelta>var.SAMPLE_MS?0:(var.SAMPLE_MS-var.timeDelta)}
	G4 P{var.waitTime}

	var sensor_diff = abs(sensors.analog[var.SENSOR_ID].lastReading - var.hangingSensorValue)
	;M118 S{"[TOUCH T"^param.T^"] Sensor diff: "^var.sensor_diff}
	set var.timerLap = state.upTime*1000+state.msUpTime

	if (var.sensor_diff <= var.HANG_THRESHOLD)
		; we are now ever so slightly on the bed
		; calculate the new UW position based on the current Z position
		M118 S{"[TOUCH T"^param.T^"] Bed at Z="^var.newPos^"mm (Backlash comp "^var.BACKLASH^"mm)"}
		set var.UWBedPosition =  var.UW_START_POSITION + var.newPos + var.BACKLASH
		M118 S{"[TOUCH T"^param.T^"] Bed at U="^var.UWBedPosition^"mm (Backlash comp "^var.BACKLASH^"mm)"}
		set var.stepOK = true
		break
M400
T-1
M400

if (!var.stepOK)
	if(param.T == 0)
		; set tool minimum to safe value
		M208 U{move.axes[3+param.T].max-1} S1

	elif(param.T == 1)
		; set tool minimum to safe value
		M208 W{move.axes[3+param.T].max-1} S1
	set global.hmiStateDetail = "error_bedtouch_t"^param.T
	M98 P"/macros/assert/abort.g" Y{"T%s calibration failed. Please clean nozzle and try again."} A{param.T,} F{var.CURRENT_FILE} E16636

M400
M598
; we are now ever so slightly on the bed
; calculate the difference to the calibration value to see if we are off
var bedDiff = (sensors.analog[var.SENSOR_ID].lastReading - var.hangingSensorValue)
M118 S{"[TOUCH T"^param.T^"] Diff to calibration value (mv): "^var.bedDiff}

; save the print position touch sensor values
set global.touchBedCalibrations[param.T] = var.UWBedPosition

M118 S{"[detect_bed_touch_hall.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit