; Description: 	
;   We will home Y to Ymin.
; TODO:
;	- doors are locked
;	- motors are powered
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homey.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"} 	F{var.CURRENT_FILE} E36100
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)} Y{"Missing module AXES"} 	F{var.CURRENT_FILE} E36101

; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}  	Y{"Missing global variable machineReadyToOperate"} 	  		F{var.CURRENT_FILE} E36102
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}  		Y{"Unexpected null value in global.machineReadyToOperate"} 	F{var.CURRENT_FILE} E36103
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}  			Y{"Unable to home as the emergency signal is active"} 	  	F{var.CURRENT_FILE} E36104

; Definitions -----------------------------------------------------------------
; [mm] Maximum tolerance to trigger the endstop out of the defined distances
var Y_TOLERANCE 	= 20	; [mm] Max tolerance in Y to endstop in the slow move

; [mm] Define max. length + tolerance in X/Y to trigger the endstop
var MOVE_LENGTH_Y	= {move.axes[1].max - move.axes[1].min + var.Y_TOLERANCE}

var SPEED_FAST_MOVE	= 4000	; [mm/s]
var SPEED_SLOW_MOVE	= 300	; [mm/s]
var Z_LIFT	= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting
var Y_RETRACTION	= 5 	; [mm] Distance to move back in Y

; Deselect the tool if needed -------------------------------------------------
var CURRENT_TOOL = state.currentTool
if(var.CURRENT_TOOL != -1)
	T-1 ; Deselect the current extruder
	M98  P"/macros/assert/result.g" R{result} Y"Unable to deselect the extruder" F{var.CURRENT_FILE}   E36105

; Making sure the big motors are ON before moving -----------------------------
M17 Y Z
G4 S0.5
M400

; Process ---------------------------------------------------------------------
; Let's make sure we are far from the bed or the print, moving up!
var errorMoving = false
if( !sensors.endstops[2].triggered )
	G91												; Relative position
	G1 H1 Z{var.Z_LIFT} F{var.SPEED_FAST_MOVE}		; Move Z up
	set var.errorMoving = (result > 0)
	M400
else
	M98 P"/macros/report/warning.g" Y{"The Z endstop is triggered before moving"} F{var.CURRENT_FILE} W36100
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to lift Z"} F{var.CURRENT_FILE} E36106

; Move quickly to X and Y axis endstops and stop there (first pass)
G91							; Relative position
G1 H1 Y{-var.MOVE_LENGTH_Y} F{var.SPEED_FAST_MOVE}
set var.errorMoving = (result > 0)
M400
G90 							; Absolute position
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move Y into the endstops"} F{var.CURRENT_FILE} 			E36107
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[1].triggered} Y{"Unable to trigger the Y endstop"} F{var.CURRENT_FILE} E36108
M400
; Let's retract a few milimiters from the endstops
G91
G1 Y{var.Y_RETRACTION} F{var.SPEED_FAST_MOVE}	; go back a few mm
set var.errorMoving = (result > 0)
M400
G90 							; Absolute position
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move in Y apart from the endstops"} F{var.CURRENT_FILE} 	E36109
M98 P"/macros/assert/abort_if.g" R{sensors.endstops[1].triggered} Y{"The Y endstop is still triggered"} F{var.CURRENT_FILE} E36111
M400
; move slowly to X and Y axis endstops once more (second pass)
G91							; Relative position
G1 H1 Y{-(var.Y_RETRACTION + var.Y_TOLERANCE)} F{var.SPEED_SLOW_MOVE}
set var.errorMoving = (result > 0)
M400
G90
G4 S0.25
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move Y into the endstops after retraction"} F{var.CURRENT_FILE} 			 E36112
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[1].triggered} Y{"Unable to trigger the Y endstop after retraction"} F{var.CURRENT_FILE} E36114
M400

; Reselect the tool -----------------------------------------------------------
if(var.CURRENT_TOOL != -1)
	T{var.CURRENT_TOOL}

M98 P"/macros/report/event.g" Y"Home Y completed" F{var.CURRENT_FILE} V36100

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; proper exit 