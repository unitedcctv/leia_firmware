; Description:
;	We will set a fixed value for the calibration value.
; Input parameters:
;	- T: Tool to use
;	- (optional) D: Extruder position where to do the calibration.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/stage/emulator/v0/calibrate_bed_touch.g"
M118 S{"[TOUCH] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing required module STAGE"} F{var.CURRENT_FILE} E16220
M98 P"/macros/assert/abort_if.g" R{!exists(global.touchBedCalibrations)} Y{"Missing global variable touchBedCalibrations"} F{var.CURRENT_FILE} E16221

set global.touchBedCalibrations[0] = 1000 ; Fixed value
set global.touchBedCalibrations[1] = 1000 ; Fixed value
M99 ; Do nothing else