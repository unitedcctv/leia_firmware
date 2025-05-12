; Description:
; 	Configuration of the ball-sensor probe. It is used for:
;		+ Homing
;		+ Zmin Endstop
;		+ Emergency: If sensor is too close to the bed.
;		+ Bed leveling
;		+ XY-Calibration
;	The Fs of the sensor is 500Hz.
; Changelog:
;	- Support to analog-endstop
;	- Support to emergency if is it too close to the bed.
; TODO:
;	- Support to BED touch
;	- Support autocalibration
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/probes/viio/v1/config.g"
M118 S{"[config.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_PROBES)}  	Y{"A previous PROBES configuration exists"} F{var.CURRENT_FILE} E15151

; DEFINITIONS -----------------------------------------------------------------
global PROBE_SENSOR_PORT 		= "70.ball"		; Port where the probe is connected.

; Offset from the ball sensor to the tool 0
global PROBE_OFFSET_Z 		= -4 			; [mm] Offset in Z refered to tool 0
; Offset from 0 where bed leveling will start
global PROBE_START_X 		= -45			; [mm] First point of the besh mesh in X
global PROBE_START_Y 		= 0				; [mm] First point of the besh mesh in Y

global PROBE_MAXIMUM 		= 1500 			; [um] Distance reported once the sensor 
											; is not touching the bed
global PROBE_VALUE_AT_Z 	= 0				; [um] distance where global.probeZ was 
											; measured

global PROBE_MAXIMUM_RANGE 	= {1000, 3900} 	; [um] {min, max} When the probe is
										  	; not touching the bed the probe value 
										  	; should be in this range.

var PROBE_SENSOR_NAME =	"dist_bed_ball[um]"	; Name used to idenfity the probe sensor 
var PROBE_SENSOR_TYPE = "linear-analog"		; Type of sensor related to the probe

M98 P"/macros/get_id/sensor.g"
global PROBE_SENSOR_ID = global.sensorId 	; SENSOR ID.

var DEFAULT_PROBE_MAX = 1200				; [um]
M98 P"/macros/variable/load.g" N"probe_max_value" D{var.DEFAULT_PROBE_MAX}
var PROBE_OFFSET_PARAM = global.savedValue - var.DEFAULT_PROBE_MAX

global probeParameters = {(-5462.51-var.PROBE_OFFSET_PARAM), (6014.23-var.PROBE_OFFSET_PARAM)}
											; [um] parameters used to pass from ADC 
											; to um. NOTE: (!) Should be const but
											; The calibration may need to change it

; CONFIGURATION ---------------------------------------------------------------
; Making sure the board is available
; M98 P"/macros/assert/board_present.g" D70 Y"Stage board is required for PROBES" F{var.CURRENT_FILE} E15152

; Creation of the sensor
M308 S{global.PROBE_SENSOR_ID} P{global.PROBE_SENSOR_PORT} Y{var.PROBE_SENSOR_TYPE} F1 B{global.probeParameters[0]} C{global.probeParameters[1]} A{var.PROBE_SENSOR_NAME}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create probe sensor" F{var.CURRENT_FILE} E15153

global MODULE_PROBES = 0.2	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[config.g] Configured "^var.CURRENT_FILE}
M99 ; Proper exit