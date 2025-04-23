; Description:
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/probes/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_PROBES)}  	Y{"A previous PROBES configuration exists"} F{var.CURRENT_FILE} E15125

; DEFINITIONS --------------------------------------------------------------------------------
; Offset from the ball sensor to the tool 0
global PROBE_OFFSET_Z = -4 		; [mm] Offset in Z refered to tool 0
; Offset from 0 where bed leveling will start
global PROBE_START_X = -35		; [mm] First point of the besh mesh in X
global PROBE_START_Y = 0		; [mm] First point of the besh mesh in Y

; Sensor values
var X_INCL = ( random(500)-250 ) / 1000000.0
var Y_INCL = ( random(500)-250 )  / 1000000.0		
var X_OFFSET =  500 + ( random(20)-10 )				; [mm] Centre in X of the parabola and plane
var Y_OFFSET =  250 + ( random(20)-10 )				; [mm] Centre in Y of the parabola and plane
var Z_OFFSET =  450 + ( random(500) / 10 )			; [mm] We start with an offset that will change once homed
var A_PARABOLA = 1500 + ( random(50)-25 )			; Parabola parameter 'a' ( x^2/a^2 + y^2/b^2 = z)
var B_PARABOLA = 1700 + ( random(100)-50 )			; Parabola parameter 'b' ( x^2/a^2 + y^2/b^2 = z)
var NOISE_AMPLITUD = 10								; [um] Noise amplitud
var MAX_VALUE =	1800 + ( random(50)-25 )			; [um] Sensor max. value without noise
var MIN_VALUE =	-2400 + ( random(20)-10 )			; [um] Sensor min. value without noise

global PROBE_MAXIMUM = var.MAX_VALUE			 	; [um] Distance reported once the sensor is not touching the bed
global PROBE_VALUE_AT_Z = 0							; [um] Distance where global.probeZ was measured

global PROBE_MAXIMUM_RANGE = {1000, 2200} 			; [um] {min, max} When the probe is 
										 			; not touching the bed the probe value 
										  			; should be in this range.

var NAME =	"dist_bed_ball[um]"	; Name used to idenfity the probe sensor 

M98 P"/macros/get_id/sensor.g"
global PROBE_SENSOR_ID = global.sensorId 	; SENSOR ID.

; CONFIGURATION ------------------------------------------------------------------------------
M308 S{global.PROBE_SENSOR_ID} Y"emulinear" A{var.NAME} H{var.X_INCL} V{var.Y_INCL} W{var.X_OFFSET} D{var.X_OFFSET} Z{var.Z_OFFSET} J{var.A_PARABOLA} K{var.B_PARABOLA} N{var.NOISE_AMPLITUD} T{var.MAX_VALUE} B{var.MIN_VALUE}
M98 P"/macros/assert/result.g" R{result} Y"Unable to create emulated probe" F{var.CURRENT_FILE} E15126

global MODULE_PROBES = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit