; Description: 	
;	The start.g will be called  when you pause a print.
;	In this the 
;		   - lift Z by 5mm
;		   - absolute positioning
;		   - Move the extruder to X=0 Y=0
; -----------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/pause.g"
M118 S{"[PAUSE] Starting  "^var.CURRENT_FILE}
; Pausing from wiping
; Checking if files exists
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/generic/reset_idle_timer.g"} F{var.CURRENT_FILE} E33303

; definitions
var XY_SPEED = 12000
var Z_SPEED = 1000
var Z_LIFT_AMOUNT = 5

; saving the t0 and t1 temps
var TEMP_T0 = exists(tools[0]) ? heat.heaters[tools[0].heaters[0]].active : null
var TEMP_T1 = exists(tools[1]) ? heat.heaters[tools[1].heaters[0]].active : null
if (!exists(global.lastPrintingTemps))
	global lastPrintingTemps = {var.TEMP_T0, var.TEMP_T1}
else
	set global.lastPrintingTemps = {var.TEMP_T0, var.TEMP_T1}

if (!exists(global.lastPrintingTool)) ; needs to be checked in case we are pausing after a power recovery resume
	global lastPrintingTool = state.currentTool
else
	set global.lastPrintingTool = state.currentTool

; Saving the variables in case of a cancel -----------------------------------
if(!exists(global.pausedPrintDuration))
	global pausedPrintDuration = job.duration
else 
	set global.pausedPrintDuration = job.duration

if(!exists(global.pausedPrintWarmUp))
	global pausedPrintWarmUp = job.warmUpDuration
else 
	set global.pausedPrintWarmUp = job.warmUpDuration

; Move to the safe park position ----------------------------------------------
G29 S2 ;disable bed map
M400

; only move if homed, in case pause is pressed before homing finishes.
; If this errors out the printer could be stuck in pausing state
if move.axes[2].homed
	G91 ; Relative move
	; lifting Z only until endstop if it's at the top already
	G1 Z{var.Z_LIFT_AMOUNT} F{var.Z_SPEED} H4
	G90
	M400
	if move.axes[0].homed && move.axes[1].homed
		; do not go all the way to min. go to the middle between axis min and 0
		var X_PAUSE_POS = move.axes[0].min / 2
		var Y_PAUSE_POS = move.axes[1].min / 2

		G1 Y{move.axes[1].min} F{var.XY_SPEED}
		G1 X{move.axes[0].min} F{var.XY_SPEED}
	M400
M400

; reset heater idle timers
M98 P"/macros/generic/reset_idle_timer.g"
; -----------------------------------------------------------------------------
M118 S{"[PAUSE] Done "^var.CURRENT_FILE}
M99 ;Proper exit
