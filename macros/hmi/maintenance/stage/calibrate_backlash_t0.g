;---------------------------------------------------------------------------------------------
; Description:
; 	This macro will calibrate the lifting system backlash to be applied when doing bed touch
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/stage/calibrate_backlash_t0.g"
M118 S{"[calibrate_backlash_t0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check the files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/stage/viio/v2/calibrate_backlash.g"} F{var.CURRENT_FILE} E89020

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

; move z to a safe position
var AXES_HOMED = move.axes[0].homed && move.axes[1].homed && move.axes[2].homed
if (!var.AXES_HOMED)
	G28
M400
; call the test macro
M98 P"/sys/modules/stage/viio/v2/calibrate_backlash.g" T0
M400


; unlock the door----------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------
M118 S{"[calibrate_backlash_t0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit