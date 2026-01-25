; Description: 		
;	Configuration to support the safety features for the Studio 3
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/safety/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_SAFETY)}  Y{"A previous SAFETY configuration exists"} F{var.CURRENT_FILE} E15600

M98 P"/macros/assert/abort_if.g" R{!exists(global.BED_HAZARD_TEMP)} Y{"Missing global variable BED_HAZARD_TEMP"} F{var.CURRENT_FILE} E15601
M98 P"/macros/assert/abort_if_null.g" R{global.BED_HAZARD_TEMP} Y{"Global variable BED_HAZARD_TEMP is null"} F{var.CURRENT_FILE} E15602
; Adding to daemon
M98 P"/macros/files/daemon/add.g" F"/sys/modules/safety/daemon.g"

global MODULE_SAFETY = 0.1	; Setting the current version of this module

; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit