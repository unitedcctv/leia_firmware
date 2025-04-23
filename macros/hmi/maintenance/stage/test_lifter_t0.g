;---------------------------------------------------------------------------------------------
; Description:
; 	This macro will test if the lifter motors lose steps
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/stage/test_lifter_t0.g"
M118 S{"[test_lifter_t0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check the files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/stage/test_steploss_lifter.g"} F{var.CURRENT_FILE} E89010

M98 P"/macros/doors/lock.g"
; move z to a safe position
if (!move.axes[2].homed || move.axes[2].machinePosition < 20)
	G91
	G1 H1 Z20
	G90
M400

; call the test macro
M98 P"/macros/stage/test_steploss_lifter.g" T0
M400

M98 P"/macros/doors/unlock.g"
M98 P"/macros/report/event.g" Y{"Lifter test for T0 successful"} F{var.CURRENT_FILE} V89010

if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
M400
;---------------------------------------------------------------------------------------------
M118 S{"[test_lifter_t0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit