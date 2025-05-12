; Description:
; 	The configuration file for stage where all the components such as the hall sensors, the
;	extruders, the calibration offsets the lifting motors and the endstops of the lifting
;	motors are defined here
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/viio/v2/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_STAGE)}  	Y{"A previous STAGE configuration exists"} F{var.CURRENT_FILE} E16110
;M98 P"/macros/assert/board_present.g" D70 Y"Board 70 is required for STAGE" F{var.CURRENT_FILE} E16111
; DEFINITIONS --------------------------------------------------------------------------------
var LIFTING_MOTOR_T0 = 70.0				 			; Lifiting motor of Tool 0
var LIFTING_MOTOR_T1 = 70.1				 			; Lifiting motor of Tool 1
var ENDSTOP_T0	  = "!70.io0.in"					; variable to store the pin of active-high endstop for high end on U
var ENDSTOP_T1	  = "!70.io2.in"					; variable to store the pin of active-high endstop for high end on W
var TOUCH_BED_SENSOR_PORTS = {"70.hall0", "70.hall1"}	; variable to store the pins of hall sensors

global TOOL_LIFTER_AXES = {"U","W"}					; Defining the related axis of the Tool 0
; Microsteps
var U_MICROSTEPPING = 32
var W_MICROSTEPPING = 32

; Steps per mm
var U_STEPS_PER_MM = 6400		; [step/mm] Motorsteps per mm for Lifiting motor of Tool 0
var W_STEPS_PER_MM = 6400		; [step/mm] Motorsteps per mm for Lifiting motor of Tool 1

; Jerk
var U_JERK = 60.00			; [mm/min] Maximum instantanous speed changes for Lifiting motor of Tool 0
var W_JERK = 60.00			; [mm/min] Maximum instantanous speed changes for Lifiting motor of Tool 1

; Speed
var U_MAX_SPEED = 2400.00		; [mm/min] Maximum speed for Lifiting motor of Tool 0
var W_MAX_SPEED = 2400.00		; [mm/min] Maximum speed for Lifiting motor of Tool 1

; Acceleration
var U_MAX_ACCELERATION = 200.00		; [mm/s^2] Acceleration for Lifiting motor of Tool 0
var W_MAX_ACCELERATION = 200.00 	; [mm/s^2] Acceleration for Lifiting motor of Tool 1

; Current and Idle factor
var U_CURRENT = 600     ; [mA] Lifiting motor of Tool 0 Current
var W_CURRENT = 600     ; [mA] Lifiting motor of Tool 1 Current
var IDLE_FACTOR = 30    ; [%] Motor Idle factor

; Axes minima and maxima
var U_MIN = 5       ; [mm] Axis minimum
var W_MIN = 5       ; [mm] Axis minimum
var U_MAX = 17      ; [mm] Axis maximum
var W_MAX = 17      ; [mm] Axis maximum

; CONFIGURATION ------------------------------------------------------------------------------

; Driver number and Direction
M569 P{var.LIFTING_MOTOR_T0} S1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T0" F{var.CURRENT_FILE} E16112
M569 P{var.LIFTING_MOTOR_T1} S1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T1" F{var.CURRENT_FILE} E16113

; Mapping axes
M584 U{var.LIFTING_MOTOR_T0}
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the lifting motor of T0" F{var.CURRENT_FILE} E16114
M584 W{var.LIFTING_MOTOR_T1}
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the lifting motor of T1" F{var.CURRENT_FILE} E16115

; Microstepping with interpolation ON
M350 U{var.U_MICROSTEPPING} I1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set microstepping for the lifting motor of T0" F{var.CURRENT_FILE} E16116
M350 W{var.W_MICROSTEPPING} I1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set microstepping for the lifting motor of T1" F{var.CURRENT_FILE} E16117

; Steps per mm
M92  U{var.U_STEPS_PER_MM}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set steps per mm for the lifting motor of T0" F{var.CURRENT_FILE} E16118
M92  W{var.W_STEPS_PER_MM}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set steps per mm for W" F{var.CURRENT_FILE} E16119

; Jerk
M566 U{var.U_JERK}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set jerk for the lifting motor of T0" F{var.CURRENT_FILE} E16120
M566 W{var.W_JERK}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set jerk for the lifting motor of T1" F{var.CURRENT_FILE} E16121

; Speeds
M203 U{var.U_MAX_SPEED}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum speed for the lifting motor of T0" F{var.CURRENT_FILE} E16122
M203 W{var.W_MAX_SPEED}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum speed for the lifting motor of T1" F{var.CURRENT_FILE} E16123

; Acceleration
M201 U{var.U_MAX_ACCELERATION}
M98 P"/macros/assert/result.g" R{result} Y"Unable to Unable to set acceleration for the lifting motor of T0" F{var.CURRENT_FILE} E16124
M201 W{var.W_MAX_ACCELERATION}
M98 P"/macros/assert/result.g" R{result} Y"Unable to Unable to set acceleration for the lifting motor of T1" F{var.CURRENT_FILE} E16125

; Current and Idle factor
M906 U{var.U_CURRENT}	I{var.IDLE_FACTOR}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set motor currents or idle factor in the lifting motor of T0" F{var.CURRENT_FILE} E16126
M906 W{var.W_CURRENT}	I{var.IDLE_FACTOR}
M98 P"/macros/assert/result.g" R{result} Y"Unable to set motor currents or idle factor in the lifting motor of T1" F{var.CURRENT_FILE} E16127

; Endstops
M574 U2 S1 P{var.ENDSTOP_T0}
M98 P"/macros/assert/result.g" R{result} Y"Unable to configure active-high endstop for high end on the lifting motor of T0" F{var.CURRENT_FILE} E16128
M574 W2 S1 P{var.ENDSTOP_T1}
M98 P"/macros/assert/result.g" R{result} Y"Unable to configure active-high endstop for high end on the lifting motor of T1" F{var.CURRENT_FILE} E16129

; Axes minima and maximim
M208 U{var.U_MIN} S1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T0 axis min" F{var.CURRENT_FILE} E16130
M208 W{var.W_MIN} S1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T1 axis min" F{var.CURRENT_FILE} E16131
M208 U{var.U_MAX} S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T0 axis max" F{var.CURRENT_FILE} E16132
M208 W{var.W_MAX} S0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of T1 axis max" F{var.CURRENT_FILE} E16133


; Creating touch sensors for bed detection ----------------------------------------

M98 P"/macros/get_id/sensor.g"						; Requesting the first sensor ID
var T0_SENSOR_ID = global.sensorId
M98 P"/macros/get_id/sensor.g"						; Requesting the second sensor ID
global TOUCH_BED_SENSOR_IDS = { var.T0_SENSOR_ID , global.sensorId }	; ID of the hall sensors
global TOUCH_BED_VALID_RANGE = {3.5, 6}									; [mm] Valid range for comparing touch sensor value to UW axis position
global UW_POSITION_THRESHOLD = 0.1										; [mm] Threshold to use position checks with linear sensor
global touchBedObstacleThresholds = {null, null}								; [mm] Threshold to use for obstacle detection
global touchBedCalibrations = {null , null}								; [mm] Values to set for U,W in calibratebedtouch.g
global touchBedSensorParams = {{null,null}, {null, null}}				; B,C Parameters for each touch sensor M308 call
global touchBedSensorBacklash = {0.1, 0.1} 								; [mm] Backlash for touch sensors, in theory it should be one global value becaus it depends on the stage hardware but just in case
global toolPositioningFailed = {false, false}							; Flag to indicate if the tool positioning failed

; Creating touch sensors / position sensors for UW
; Note: linear potentiometers are used in place of the hall sensors
M98 P"/macros/variable/load.g" N"global.touchBedSensorParams"
M400
if (global.savedValue == null || #global.savedValue < 2)
	M118 S{"[CONFIG] Touch sensor parameters not found, assuming hall sensors"}
else
	M118 S{"[CONFIG] Loaded touch sensor parameters: " ^ global.savedValue}
	set global.touchBedSensorParams = global.savedValue

var HAS_T0_LINEAR_SENSOR = global.touchBedSensorParams[0] != null && global.touchBedSensorParams[0][0] != null && global.touchBedSensorParams[0][1] != null
var HAS_T1_LINEAR_SENSOR = global.touchBedSensorParams[1] != null && global.touchBedSensorParams[1][0] != null && global.touchBedSensorParams[1][1] != null

global touchLinearInstalled = {var.HAS_T0_LINEAR_SENSOR, var.HAS_T1_LINEAR_SENSOR}

; T0 Sensor
if var.HAS_T0_LINEAR_SENSOR
	set global.touchBedObstacleThresholds[0] = 0.5
	var B = global.touchBedSensorParams[0][0]
	var C = global.touchBedSensorParams[0][1]
	M308 S{global.TOUCH_BED_SENSOR_IDS[0]} P{var.TOUCH_BED_SENSOR_PORTS[0]} Y"linear-analog" F1 B{var.B} C{var.C} A"touch_t0[mm]"
	M98 P"/macros/assert/result.g" R{result} Y"Unable to create linear touch sensor for T0" F{var.CURRENT_FILE} E16134
else
	set global.touchBedObstacleThresholds[0] = 200
	M308 S{global.TOUCH_BED_SENSOR_IDS[0]} P{var.TOUCH_BED_SENSOR_PORTS[0]} Y"linear-analog" F1 B0 C3300 A"hall_ext_0[mV]"
	M98 P"/macros/assert/result.g" R{result} Y"Unable to create hall sensor for T0" F{var.CURRENT_FILE} E16135

; T1 Sensor
if var.HAS_T1_LINEAR_SENSOR
	set global.touchBedObstacleThresholds[1] = 0.5
	var B = global.touchBedSensorParams[1][0]
	var C = global.touchBedSensorParams[1][1]
	M308 S{global.TOUCH_BED_SENSOR_IDS[1]} P{var.TOUCH_BED_SENSOR_PORTS[1]} Y"linear-analog" F1 B{var.B} C{var.C} A"touch_t1[mm]"
	M98 P"/macros/assert/result.g" R{result} Y"Unable to create linear touch sensor for T1" F{var.CURRENT_FILE} E16136
else
	set global.touchBedObstacleThresholds[1] = 200
	M308 S{global.TOUCH_BED_SENSOR_IDS[1]} P{var.TOUCH_BED_SENSOR_PORTS[1]} Y"linear-analog" F1 B0 C3300 A"hall_ext_1[mV]"
	M98 P"/macros/assert/result.g" R{result} Y"Unable to create hall sensor for T1" F{var.CURRENT_FILE} E16137

; Set axis minimum of U and W according to last calibrated bed positions
; Tool moves to min position when selected
M98 P"/macros/variable/load.g" N"global.touchBedCalibrations"
M400
if (global.savedValue == null || #global.savedValue < 2)
	M118 S{"[CONFIG] No bed touch values found, using default values"}
else
	M118 S{"[CONFIG] Loaded bed touch values: " ^ global.savedValue}
	set global.touchBedCalibrations = global.savedValue

if (global.touchBedCalibrations[0] != null)
	M118 S{"[CONFIG] Loaded Bed touch position for lifting motor axis of T0: " ^ global.touchBedCalibrations[0] ^ "mm"}
	M208 U{global.touchBedCalibrations[0]} S1

if (global.touchBedCalibrations[1] != null)
	M118 S{"[CONFIG] Loaded Bed touch position for lifting motor axis of T1: " ^ global.touchBedCalibrations[1] ^ "mm"}
	M208 W{global.touchBedCalibrations[1]} S1


M98 P"/macros/variable/load.g" N"global.touchBedSensorBacklash"
M400
if (global.savedValue != null && #global.savedValue == 2)
	set global.touchBedSensorBacklash = global.savedValue

M118 S{"[CONFIG] global.touchBedSensorBacklash: " ^ global.touchBedSensorBacklash}

; Creating links:
M98 P"/macros/files/link/create.g" L"/macros/stage/detect_bed_touch.g" D"/sys/modules/stage/viio/v2/detect_bed_touch.g"

global MODULE_STAGE = 0.2				; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit
