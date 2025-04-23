; Description:
; 	This macro moves the U or W axis up and down 10 times while checking if the axis loses steps
;   We do this by moving down and then up in steps of 0.2mm until the endstop is triggered, our position should be the Max axis position
;   If the deviation is greater than 0.01mm we abort the test
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/stage/test_steploss_lifter.g"
M118 S{"[test_steploss_lifter.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

var TOOL			= (exists(param.T) && (param.T == 1)) ? 1 : 0
var AXIS_NUM		= 3 + var.TOOL
var AXIS_NAME		= var.TOOL == 0 ? "U" : "W"

var NUM_TESTS		= 10
var SPEED_FAST_MOVE	= 6000
var SPEED_SLOW_MOVE	= 150
var STEP_SIZE		= 0.2
var CHECK_RANGE_MIN	= 0
var AXIS_MAX		= move.axes[var.AXIS_NUM].max
var MAX_DEVIATION	= 0.01
var ABORT_AFTER_MM	= 25 ; abort after moving this far

var savedMinPosition = move.axes[var.AXIS_NUM].min
; reset min position
if var.AXIS_NAME == "U"
	M208 U0 S1
else
	M208 W0 S1
M400

M118 S{var.AXIS_NAME ^ " movement test..."}

var testNo = 0
var testOK = true
while (iterations < var.NUM_TESTS)
	set var.testNo = var.testNo + 1
	; ------------------------------
	; Home Axis
	; ------------------------------
	G91  ; Relative positioning
	if var.AXIS_NAME == "U"
		G1 H1 U{var.AXIS_MAX}+5 F{var.SPEED_FAST_MOVE}
		G1 U-5
		G1 H1 U7 F{var.SPEED_SLOW_MOVE}
	else
		G1 H1 W{var.AXIS_MAX}+5 F{var.SPEED_FAST_MOVE}
		G1 W-5
		G1 H1 W7 F{var.SPEED_SLOW_MOVE}
	M400
	; ------------------------------
	; Run test
	; ------------------------------
	G90  ; Absolute positioning
	if var.AXIS_NAME == "U"
		G1 U{var.CHECK_RANGE_MIN} F{var.SPEED_FAST_MOVE}
	else
		G1 W{var.CHECK_RANGE_MIN} F{var.SPEED_FAST_MOVE}
	M400
	G91  ; relative
	while(!sensors.endstops[var.AXIS_NUM].triggered)
		if (move.axes[var.AXIS_NUM].machinePosition > var.ABORT_AFTER_MM)
			; reset min position
			if var.AXIS_NAME == "U"
				M208 U{var.savedMinPosition} S1
			else
				M208 W{var.savedMinPosition} S1
			M400
			M98 P"/macros/assert/abort.g" Y{"%s Axis: %s/%s Could not find endstop after moving %smm"} A{var.AXIS_NAME,var.testNo,var.NUM_TESTS,var.ABORT_AFTER_MM} F{var.CURRENT_FILE} E56200
		M400
		if var.AXIS_NAME == "U"
			G1 H4 U{var.STEP_SIZE}
		else
			G1 H4 W{var.STEP_SIZE}
		M400
	M400
	var deviation = move.axes[var.AXIS_NUM].machinePosition - var.AXIS_MAX
	M118 S{var.AXIS_NAME^" Axis:"^var.testNo^"/"^var.NUM_TESTS^" - Deviation: "^var.deviation}
	if (abs(var.deviation) > var.MAX_DEVIATION)
		; reset min position
		if var.AXIS_NAME == "U"
			M208 U{var.savedMinPosition} S1
		else
			M208 W{var.savedMinPosition} S1
		M400
		M98 P"/macros/assert/abort.g" Y{"%s Axis: %s/%s - deviation %smm > %smm"} A{var.AXIS_NAME,var.testNo,var.NUM_TESTS,var.deviation,var.MAX_DEVIATION} F{var.CURRENT_FILE} E56201
		set var.testOK = false
	M400
M400

; reset min position
if var.AXIS_NAME == "U"
	M208 U{var.savedMinPosition} S1
else
	M208 W{var.savedMinPosition} S1
M400

M118 S{"[test_steploss_lifter.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit