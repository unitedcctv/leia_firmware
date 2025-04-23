; Description: 	
; 	We will turn on the top fans during a period of time.
; Input parameters:
;	- T (optional): [sec] Amout of time to keep the fans ON. The default value 
;		is 20 sec.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fat/cbc/force_fans_on.g"
M118 S{"[TOOL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; -----------------------------------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.cbcForceFansOn)} Y{"Missing required global variable cbcForceFansOn"} F{var.CURRENT_FILE} E70000

; Definitions -----------------------------------------------------------------
var DEFAULT_TIME_FANS_ON = 20 ; [sec] Default value with the fans on

; Input variables -------------------------------------------------------------
var HAS_VALID_PARAM_T = {(exists(param.T) && param.T != null && param.T > 0)}
var TIME_FANS_ON = { var.HAS_VALID_PARAM_T ? param.T : var.DEFAULT_TIME_FANS_ON }

; Process ---------------------------------------------------------------------
set global.cbcForceFansOn = true 	; Forcing the CBC fans to be ON
G4 S{var.TIME_FANS_ON}				; Dedaly
set global.cbcForceFansOn = false 	; Forcing the CBC fans to be OFF

; -----------------------------------------------------------------------------
M118 S{"[TOOL] Done "^var.CURRENT_FILE}
M99