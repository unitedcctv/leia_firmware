; Description: 	
;   We will home X and Y together to Xmin and Ymin.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homexy.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"} 	F{var.CURRENT_FILE} E35200
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)} Y{"Missing module AXES"} 	F{var.CURRENT_FILE} E35201

; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}  	Y{"Missing global variable machineReadyToOperate"} 	  		F{var.CURRENT_FILE} E35202
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}  		Y{"Unexpected null value in global.machineReadyToOperate"} 	F{var.CURRENT_FILE} E35203
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}  			Y{"Unable to home as the emergency signal is active"} 	  	F{var.CURRENT_FILE} E35204

; Definitions -----------------------------------------------------------------
; [mm] Max. tolerance to trigger the endstop out of the defined distances
var X_TOLERANCE 	= 20	; [mm] Max tolerance in X to endstop in the slow move
var Y_TOLERANCE 	= 20	; [mm] Max tolerance in Y to endstop in the slow move

; [mm] Define max. length + tolerance in X/Y to trigger the endstop
var MOVE_LENGTH_X	= {move.axes[0].max - move.axes[0].min + var.X_TOLERANCE}
var MOVE_LENGTH_Y	= {move.axes[1].max - move.axes[1].min + var.Y_TOLERANCE}

var SPEED_FAST_MOVE	= 4000	; [mm/s]
var SPEED_SLOW_MOVE	= 500	; [mm/s]
var Z_LIFT	= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting
var XY_RETRACTION_LARGE	= 30 	; [mm] Distance to move back in XY
var XY_RETRACTION_SMALL = 3		; [mm] Distance to move back in XY

var RESUMING_PRINT = {(state.status == "paused" || state.status == "resuming") && job.file.fileName != null}

; Deselect the tool and home UW if needed -------------------------------------
var CURRENT_TOOL = state.currentTool

; Making sure the big motors are ON before moving -----------------------------
M17 X Y Z
G4 S0.5
M400

; Process ---------------------------------------------------------------------
; Let's make sure we are far from the bed or the print, moving up. But only if we are not resuming from pause
if (!var.RESUMING_PRINT)
	T-1
	M400

	if( !sensors.endstops[2].triggered )
		G91												; Relative position
				; Move Z up – only seek end-stop if Z is not homed yet
		if (!move.axes[2].homed)
			G1 H1 Z{var.Z_LIFT} F{var.SPEED_FAST_MOVE} ; seek Z-max for clearance on first XY homing
		else
			G1 Z{var.Z_LIFT} F{var.SPEED_FAST_MOVE}   ; already homed → just lift a bit, no end-stop seek
		M400
	else
		M98 P"/macros/report/warning.g" Y{"The Z endstop is triggered before moving"} F{var.CURRENT_FILE} W35200
M400

; Check if we are in the endstop for X or Y 
var X_TRIGGERED_AT_START = sensors.endstops[0].triggered
var Y_TRIGGERED_AT_START = sensors.endstops[1].triggered

; Move quickly to X and Y axis endstops and stop there (first pass)
G91	; Relative position
G1 H1 X{-var.MOVE_LENGTH_X} Y{-var.MOVE_LENGTH_Y} F{var.SPEED_FAST_MOVE}
M400
G90 ; Absolute position
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[0].triggered} Y{"Unable to trigger the X endstop"} F{var.CURRENT_FILE} E35208
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[1].triggered} Y{"Unable to trigger the Y endstop"} F{var.CURRENT_FILE} E35209
M400

; Only perform big move if endstops are triggered at the beginning, since we can't tell where the 
; axes are in endstops
if( var.X_TRIGGERED_AT_START || var.Y_TRIGGERED_AT_START)
	; Let's retract a few milimiters from the endstops
	G91
	G1 X{var.XY_RETRACTION_LARGE} Y{var.XY_RETRACTION_LARGE} F{var.SPEED_FAST_MOVE}	; go back a few mm
	M400
	G90 							; Absolute position
	G4 S0.25
	M98 P"/macros/assert/abort_if.g" R{sensors.endstops[0].triggered} Y{"The X endstop is still triggered"} F{var.CURRENT_FILE} E35211
	M98 P"/macros/assert/abort_if.g" R{sensors.endstops[1].triggered} Y{"The Y endstop is still triggered"} F{var.CURRENT_FILE} E35212
	M400

	; move fast to X and Y axis endstops once more (second pass)
	G91							; Relative position
	G1 H1 X{-(var.XY_RETRACTION_LARGE + var.X_TOLERANCE)} Y{-(var.XY_RETRACTION_LARGE + var.Y_TOLERANCE)} F{var.SPEED_FAST_MOVE}
	M400
	G90
	G4 S0.25
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[0].triggered} Y{"Unable to trigger the X endstop after retraction"} F{var.CURRENT_FILE} E35214
	M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[1].triggered} Y{"Unable to trigger the Y endstop after retraction"} F{var.CURRENT_FILE} E35215
	M400

; Let's retract a few milimiters from the endstops
G91
G1 X{var.XY_RETRACTION_SMALL} Y{var.XY_RETRACTION_SMALL} F{var.SPEED_FAST_MOVE}	; go back a few mm
M400
G90 							; Absolute position
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{sensors.endstops[0].triggered} Y{"The X endstop is still triggered"} F{var.CURRENT_FILE} E35217
M98 P"/macros/assert/abort_if.g" R{sensors.endstops[1].triggered} Y{"The Y endstop is still triggered"} F{var.CURRENT_FILE} E35218
M400

; move slowly to X and Y axis endstops once more (third pass)
G91							; Relative position
G1 H1 X{-(var.XY_RETRACTION_SMALL + var.X_TOLERANCE)} Y{-(var.XY_RETRACTION_SMALL + var.Y_TOLERANCE)} F{var.SPEED_SLOW_MOVE}
M400
G90
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[0].triggered} Y{"Unable to trigger the X endstop after retraction"} F{var.CURRENT_FILE} E35221
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[1].triggered} Y{"Unable to trigger the Y endstop after retraction"} F{var.CURRENT_FILE} E35222
M400


; Reselect the tool -----------------------------------------------------------
T{var.CURRENT_TOOL}
M400
M98 P"/macros/report/event.g" Y"Home XY completed" F{var.CURRENT_FILE} V35200

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; proper exit 