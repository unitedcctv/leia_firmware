; Description:
;	The emergency of the probe was triggered. We may need to stop.
; TODO: Turn everything off
;------------------------------------------------------------------------------
; Restarting if we are moving and emergency was triggered -------------------------
; (!) This is the important part!
; We need to disable the restarting if we are performing the xy-calibration
; Definitions---------------------------------------------------------------
var AXES_MOVING = ((move.currentMove.requestedSpeed > 0))
var XY_CAL_RUNNING = (exists(global.xyCalibrationRunning) && global.xyCalibrationRunning)

; check the trigger condtions
if(var.AXES_MOVING && !var.XY_CAL_RUNNING)
	; turn off all motors
	; (!) IMPORTANT: Reset the boards. The machine is going to restart!
	set global.hmiStateDetail = "error_obstacle"
	set global.errorRestartRequired = true

	M98 P"/macros/report/warning.g" Y{"Bed probe triggered while moving! Check for Hardware damage and restart machine"} W23004
	M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
	M112; M112 reacts way faster than M999
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/trigger_emergency_probe.g"

M118 S{"[trigger_emergency_probe.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
M118 S{"[trigger_emergency_probe.g] Probe Triggered but machine is not moving, nothing to do"}
; -----------------------------------------------------------------------------
M118 S{"[trigger_emergency_probe.g] Done "^var.CURRENT_FILE}
M99