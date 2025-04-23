; Description: 		Macro to call the bed touch macro for T1
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/stage/bed_touch_t1.g"
M118 S{"[bed_touch_t1.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_EXTRUDER_1)} Y{"Missing required module extruder 1"} F{var.CURRENT_FILE} E56151
; calling the macro
M98 P"/macros/stage/detect_bed_touch.g" T1
;---------------------------------------------------------------------------------------------
M118 S{"[bed_touch_t1.g] Done "^var.CURRENT_FILE}
M99