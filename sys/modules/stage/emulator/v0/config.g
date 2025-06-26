; Description: 
; 	The configuration file for stage where all the components such as the hall sensors, the 
;	extruders, the calibration offsets the lifting motors and the endstops of the lifting 
;	motors are defined here
; TODO: Support to emulated TOUCH_BED Sensor
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_STAGE)}  	Y{"A previous STAGE configuration exists"} F{var.CURRENT_FILE} E16190

; DEFINITIONS --------------------------------------------------------------------------------
var LIFTING_MOTOR_E0 	= 0.3				 	; Lifiting motor of Tool 0
var LIFTING_MOTOR_E1 	= 0.4				 	; Lifiting motor of Tool 1
var ENDSTOP_E0	  		= "0.io3.in"			; variable to store the pin of active-high endstop for high end on U
var ENDSTOP_E1	  		= "0.io4.in"			; variable to store the pin of active-high endstop for high end on W
; var TOUCH_BED_SENSOR_PORT_E0 = "70.hall0"			; variable to store the pin of hall sensor in the Tool 0
; var TOUCH_BED_SENSOR_PORT_E1 = "70.hall1"			; variable to store the pin of hall sensor in the Tool 1
; Microsteps
var U_MICROSTEPPING = 32
var W_MICROSTEPPING = 32

; Steps per mm
var U_STEPS_PER_MM = 6400		; [step/mm] Motorsteps per mm for Lifiting motor of Tool 0
var W_STEPS_PER_MM = 6400		; [step/mm] Motorsteps per mm for Lifiting motor of Tool 1

; Jerk
var U_JERK = 900.00			; [mm/min] Maximum instantanous speed changes for Lifiting motor of Tool 0
var W_JERK = 900.00			; [mm/min] Maximum instantanous speed changes for Lifiting motor of Tool 1

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
var U_MIN = 0       ; [mm] Axis minimum
var W_MIN = 0       ; [mm] Axis minimum
var U_MAX = 17      ; [mm] Axis maximum
var W_MAX = 17      ; [mm] Axis maximum
; M98 P"/macros/get_id/sensor.g"
; global TOUCH_BED_SENSOR_ID_E0 = global.sensorId		; ID of the bed sensor in the extruder0
; M98 P"/macros/get_id/sensor.g"
; global TOUCH_BED_SENSOR_ID_E1 = global.sensorId		; ID of the bed sensor in the extruder1

global touchBedCalibrations = {null , null}		; [mm] Values to set in calibrate_bed_touch.g. Initialize with negative value (not valid).

global AXIS_NAME_E0 = "U"						; Defining the related axis of the Tool 0
global AXIS_NAME_E1 = "W"						; Defining the related axis of the Tool 1

; CONFIGURATION ------------------------------------------------------------------------------

; Calculating parameters
; Direction
M569 P{var.LIFTING_MOTOR_E0} S1								; set motordriver and direction
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of tool 0" F{var.CURRENT_FILE} E16191
M569 P{var.LIFTING_MOTOR_E1} S1								; set motordriver and direction
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the lifting motor of tool 1" F{var.CURRENT_FILE} E16192

; Mapping axes
M584 U{var.LIFTING_MOTOR_E0}  ; Setting up the extruder axis U
M98 P"/macros/assert/result.g" R{result} Y"Unable to setting up the lifting axis U" F{var.CURRENT_FILE} E16193
M584 W{var.LIFTING_MOTOR_E1}	; Setting up the extruder axis W
M98 P"/macros/assert/result.g" R{result} Y"Unable to setting up the lifting axis W" F{var.CURRENT_FILE} E16194

; Microstepping
M350 U{var.U_MICROSTEPPING}	   I1	  			; set the microstepping for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping for U" F{var.CURRENT_FILE} E16195
M350 W{var.W_MICROSTEPPING}	   I1	  			; set the microstepping for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping for W" F{var.CURRENT_FILE} E16196

; Steps per mm
M92  U{var.U_STEPS_PER_MM}	 					; set steps per mm for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set steps per mm for U" F{var.CURRENT_FILE} E16197
M92  W{var.W_STEPS_PER_MM}	 					; set steps per mm for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set steps per mm for W" F{var.CURRENT_FILE} E16198

; Jerk
M566 U{var.U_JERK}   					; [mm/min] Set maximum instantaneous speed changes for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum instantaneous speed changes for U" F{var.CURRENT_FILE} E16199
M566 W{var.W_JERK}   					; [mm/min] Set maximum instantaneous speed changes for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum instantaneous speed changes for W" F{var.CURRENT_FILE} E16200

; Speeds
M203 U{var.U_MAX_SPEED}  					; [mm/min] set maximum speeds for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum speeds for U" F{var.CURRENT_FILE} E16201
M203 W{var.W_MAX_SPEED}  					; [mm/min] set maximum speeds for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set maximum speeds for W" F{var.CURRENT_FILE} E16202

; Acceleration
M201 U{var.U_MAX_ACCELERATION}   					; [mm/s^2] set accelerations for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to Unable to set accelerations for U" F{var.CURRENT_FILE} E16203
M201 W{var.W_MAX_ACCELERATION}   					; [mm/s^2] set accelerations for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to Unable to set accelerations for W" F{var.CURRENT_FILE} E16204

; Current and Idle factor
M906 U{var.U_CURRENT}	I{var.IDLE_FACTOR}   				; [mA][%] Set motor currents and motor idle factor in per cent for U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set motor currents or idle factor in U" F{var.CURRENT_FILE} E16205
M906 W{var.W_CURRENT}	I{var.IDLE_FACTOR}					; [mA][%] Set motor currents and motor idle factor in per cent for W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set motor currents or idle factor in W" F{var.CURRENT_FILE} E16206

; Endstops
M574 U2 S1 P{var.ENDSTOP_E0}   	; Configure active-high endstop for high end on U
M98 P"/macros/assert/result.g" R{result} Y"Unable to configure active-high endstop for high end on U" F{var.CURRENT_FILE} E16207
M574 W2 S1 P{var.ENDSTOP_E1}   	; Configure active-high endstop for high end on W
M98 P"/macros/assert/result.g" R{result} Y"Unable to configure active-high endstop for high end on W" F{var.CURRENT_FILE} E16208

; Axes minima and maximim
M208 U{var.U_MIN} S1 						; [mm] Set axis minima in U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set axis minima in U" F{var.CURRENT_FILE} E16209
M208 W{var.W_MIN} S1 						; [mm] Set axis minima in W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set axis minima in W" F{var.CURRENT_FILE} E16210
M208 U{var.U_MAX} S0 					; [mm] Set axis maxima in U
M98 P"/macros/assert/result.g" R{result} Y"Unable to set axis maxima in U" F{var.CURRENT_FILE} E16211
M208 W{var.W_MAX} S0 					; [mm] Set axis maxima in W
M98 P"/macros/assert/result.g" R{result} Y"Unable to set axis maxima in W" F{var.CURRENT_FILE} E16212

; M308 S{global.TOUCH_BED_SENSOR_ID_E0} P{var.TOUCH_BED_SENSOR_PORT_E0} Y"linear-analog" F1 B0 C3300 A"hall_ext_0[mV]"
; M98 P"/macros/assert/result.g" R{result} Y"Unable to create the hall sensor in the tool 0"
; M308 S{global.TOUCH_BED_SENSOR_ID_E1} P{var.TOUCH_BED_SENSOR_PORT_E1} Y"linear-analog" F1 B0 C3300 A"hall_ext_1[mV]"
; M98 P"/macros/assert/result.g" R{result} Y"Unable to create the hall sensor in the tool 1"

; Creating links:
M98 P"/macros/files/link/create.g" L"/macros/stage/calibrate_bed_touch.g" D"/sys/modules/stage/emulator/v0/calibrate_bed_touch.g"
M98 P"/macros/files/link/create.g" L"/macros/stage/detect_bed_touch.g" D"/sys/modules/stage/emulator/v0/detect_bed_touch.g"
M98 P"/macros/files/link/create.g" L"/sys/homeu.g"	D"/sys/modules/stage/emulator/v0/homing/u.g"
;M98 P"/macros/files/link/create.g" L"/sys/homeuw.g"	D"/sys/modules/stage/emulator/v0/homing/uw.g"
M98 P"/macros/files/link/create.g" L"/sys/homew.g"	D"/sys/modules/stage/emulator/v0/homing/w.g"

; Loading the bed touch values
M98 P"/macros/variable/load.g" N"global.touchBedCalibrations"  ; Will be null if not existing
M598
if (global.savedValue == null)
    M118 S{"[CONFIG] No bed touch values found, using default values"}
elif (#global.savedValue < 2)
    M118 S{"[CONFIG] global.bedTouchCalibrations has invalid format, using default"}
else
    M118 S{"[CONFIG] Loaded bed touch values: " ^ global.savedValue}
    set global.touchBedCalibrations = global.savedValue

if (global.touchBedCalibrations[0] != null)
    M118 S{"[CONFIG] Loaded Bed touch value for U: " ^ global.touchBedCalibrations[0] ^ "mm"}
    M208 U{global.touchBedCalibrations[0]} S1

if (global.touchBedCalibrations[1] != null)
    M118 S{"[CONFIG] Loaded Bed touch value for W: " ^ global.touchBedCalibrations[1] ^ "mm"}
    M208 W{global.touchBedCalibrations[1]} S1


global MODULE_STAGE = 0.1				; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit