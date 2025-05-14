; Description:
; 	Bltouch sensor on the Y board CAN 20
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/probes/viio/v1/config.g"
M118 S{"[config.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_PROBES)}  	Y{"A previous PROBES configuration exists"} F{var.CURRENT_FILE} E15151

; DEFINITIONS -----------------------------------------------------------------
global PROBE_SENSOR_PIN 		= "20.io4.in"		; Port where the probe is connected.
global PROBE_CONTROL_PIN 		= "20.io5.out"		; Pin used to control the probe

var PROBE_SENSOR_NAME =	"bltouch"	; Name used to idenfity the probe sensor 
var PROBE_SENSOR_TYPE = "pwmswitch"		; Type of sensor related to the probe
var PROB_DIVE_HEIGHT = 10					; [mm] Height of the dive
var PROBING_SPEED = 120					; [mm/s] Speed of the dive

M98 P"/macros/get_id/sensor.g"
global PROBE_SENSOR_ID = global.sensorId 	; SENSOR ID.

;M950 P0 C{global.PROBE_CONTROL_PIN}
M558 P9 C{global.PROBE_SENSOR_PIN} H{var.PROBE_DIVE_HEIGHT} F{var.PROBING_SPEED} T{var.PROB_DIVE_HEIGHT}


global MODULE_PROBES = 0.2	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[config.g] Configured "^var.CURRENT_FILE}
M99 ; Proper exit