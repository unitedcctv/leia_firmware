; Description:
; 	Bltouch sensor on the Duet 3 Toolboard 1LC board CAN 20
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/probes/config.g"
M118 S{"[config.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_PROBES)}  	Y{"A previous PROBES configuration exists"} F{var.CURRENT_FILE} E15151

; DEFINITIONS -----------------------------------------------------------------
var PROBE_SENSOR_PIN  = "20.io0.in"
var PROBE_CONTROL_PIN = "20.io0.out"
var PROBE_DIVE_HEIGHT = 10          ; mm
var PROBING_SPEED     = 600         ; mm/min  (dive speed)
var TRAVEL_SPEED      = 6000        ; mm/min  (between points)
var PROBE_OFFSET_X    = 60			; [mm] Offset of the probe in X
var PROBE_OFFSET_Y    = -10		; [mm] Offset of the probe in Y
var PROBE_OFFSET_Z    = 5			; [mm] Offset of the probe in Z

global PROBE_OFFSET_Z = var.PROBE_OFFSET_Z		; [mm] Offset of the probe in Z
global PROBE_START_X = 50		; [mm] First point of the besh mesh in X
global PROBE_START_Y = 21		; [mm] First point of the besh mesh in Y
global PROBE_SENSOR_ID = 0    	; ID of the sensor      

M950  S0 C{var.PROBE_CONTROL_PIN}         ; SERVO channel for BLTouch
M558  P9 C{var.PROBE_SENSOR_PIN} H{var.PROBE_DIVE_HEIGHT} F{var.PROBING_SPEED} \
      T{var.TRAVEL_SPEED}
G31   P500 X{var.PROBE_OFFSET_X} Y{var.PROBE_OFFSET_Y} Z{var.PROBE_OFFSET_Z}

global MODULE_PROBES = 0.2	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[config.g] Configured "^var.CURRENT_FILE}
M99 ; Proper exit