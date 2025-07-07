; Description: 	
;   Homing to Z max.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/hometozmax.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}   Y{"Missing required module AXES"}				F{var.CURRENT_FILE} E36500

; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}  	Y{"Missing global variable machineReadyToOperate"} 	  		F{var.CURRENT_FILE} E36501
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}  		Y{"Unexpected null value in global.machineReadyToOperate"} 	F{var.CURRENT_FILE} E36502
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}  			Y{"Unable to home as the emergency signal is active"} 	  	F{var.CURRENT_FILE} E36503

; Definitions -----------------------------------------------------------------
var MOVEMENT_SPEED		= 10000		; [mm/min] Speed used in local moves
var Z_UP_SPEED			= 500		; [mm/min] Speed to use while moving up
var Z_RETRACTION_SPEED	= 250		; [mm/min] Speed used in the retraction
var Z_LIFT_SPEED		= 6000		; [mm/min] Speed used when lifting Z
var Z_LIFT				= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting
var X_CENTRE			= (move.axes[0].max - move.axes[0].min) / 2		; [mm] Centre position in X
var Y_CENTRE			= (move.axes[1].max - move.axes[1].min) / 2		; [mm] Centre position in Y
var Z_LENGTH			= (move.axes[2].max - move.axes[2].min)			; [mm] Length of Z
var Z_RETRACTION		= 5 ; [mm] Distance to move back in Z
var FINAL_POSITION		= {global.PROBE_START_X, global.PROBE_START_Y, 20}	; [mm] XYZ position
; Process ---------------------------------------------------------------------
var errorMoving = false					; Used to record the result of a move.

M400	; Making sure the machine is not moving 

; Deselect the extruder -------------------------------------------------------
var CURRENT_TOOL = state.currentTool
if(var.CURRENT_TOOL != -1)
	T-1 ; Deselect the current extruder
	M98  P"/macros/assert/result.g" R{result} Y"Unable to deselect the extruder" F{var.CURRENT_FILE}   E36504

; Making sure the big motors are ON before moving -----------------------------
M17 X Y Z
G4 S0.5
M400

; Let's home XY ---------------------------------------------------------------
M98 P"/sys/homexy.g" ; (!) This also lifts

; Moving to middle of the machine in XY ---------------------------------------
G90 ; Absolute position
G1 X{var.X_CENTRE} Y{var.Y_CENTRE} F{var.MOVEMENT_SPEED}
set var.errorMoving = (result > 0)
M400
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move XY into the centre position"} F{var.CURRENT_FILE} E36505

M118 S{"[HOMING] Moving up to Zmax"}

; Let's move up ---------------------------------------------------------------
G91 ; Relative position
G1 H1 Z{var.Z_LENGTH} F{var.Z_UP_SPEED}
set var.errorMoving = (result > 0)
M400
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move to Zmax"} F{var.CURRENT_FILE} E36506
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[2].triggered} Y{"Unable to trigger the Z endstop"} F{var.CURRENT_FILE} E36507

; Slow aproach ----------------------------------------------------------------
; First we separate from the endstops
G1 H2 Z{-var.Z_RETRACTION} F{var.Z_RETRACTION_SPEED}
set var.errorMoving = (result > 0)
M400
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move to Zmax"} F{var.CURRENT_FILE} E36508
M98 P"/macros/assert/abort_if.g" R{sensors.endstops[2].triggered} Y{"The Z endstop is still triggered"} F{var.CURRENT_FILE} E36509

; Now we try to reach them again
G1 H1 Z{var.Z_RETRACTION*2} F{var.Z_RETRACTION_SPEED}
set var.errorMoving = (result > 0)
M400
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move to Zmax"} F{var.CURRENT_FILE} E36510
M98 P"/macros/assert/abort_if.g" R{!sensors.endstops[2].triggered} Y{"Unable to trigger the Z endstop after retraction"} F{var.CURRENT_FILE} E36511

M98 P"/macros/report/event.g" Y"Home Zmax completed" F{var.CURRENT_FILE} V36500

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99