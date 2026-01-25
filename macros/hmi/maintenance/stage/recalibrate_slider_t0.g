;---------------------------------------------------------------------------------------------
; Description:
; 	This macro will recalibrate the slider sensor used for lifter position checking
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/stage/recalibrate_slider_t0.g"
M118 S{"[recalibrate_slider_t0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check the files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/stage/calibrate_pos_sensor.g"} F{var.CURRENT_FILE} E89015

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

; move z to a safe position
if (!move.axes[2].homed || move.axes[2].machinePosition < 20)
	G91
	G1 H1 Z20
	G90
M400

; call the test macro
M98 P"/sys/modules/stage/calibrate_pos_sensor.g" T0
M400

T-1
M400
; unlock the door----------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------
M118 S{"[recalibrate_slider_t0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit