;---------------------------------------------------------------------------------------------
; Description:
; 	This macro will test the  validity of the bed touch calibration
;   it does the bed touch calibration and leaves Z at 1mm
;   so the user can validate correct calibration using a feeler gauge
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/stage/test_bed_touch_t0.g"
M118 S{"[test_bed_touch_t0.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check the files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/stage/detect_bed_touch.g"} F{var.CURRENT_FILE} E89001
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/lock.g"} F{var.CURRENT_FILE} E89002
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} F{var.CURRENT_FILE} E89003

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

var AXES_HOMED = move.axes[0].homed && move.axes[1].homed && move.axes[2].homed
if (!var.AXES_HOMED)
	G28
M400

; call the test macro
M98 P"/macros/stage/detect_bed_touch.g" T0
M400

var zPosition = (exists(param.Z) && param.Z > 0) ? param.Z : 1
if exists(global.probeMeasuredValue) && global.probeMeasuredValue != null
	G1 Z{var.zPosition + global.probeMeasuredValue} F300
else
	G1 Z{var.zPosition} F300
M400

; unlock the door----------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

M98 P"/macros/report/event.g" Y{"T0 touch test done. Check nozzle distance with %smm feeler gauge"} A{var.zPosition,} F{var.CURRENT_FILE} V89003
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------
M118 S{"[test_bed_touch_t0.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit