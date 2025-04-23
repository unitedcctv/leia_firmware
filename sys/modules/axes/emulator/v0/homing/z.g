; Description:
;   Emulated homing Z routine with probe. 
; Parameter: 
;   - T1: Homing from homeall.g, following homexy.g
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/emulator/v0/homing/z.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/move_z_to_probe_position.g"} 					F{var.CURRENT_FILE} E10330
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}	Y{"Missing required module AXES"}			F{var.CURRENT_FILE} E10331
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)}   Y{"Missing required module STAGE"}			F{var.CURRENT_FILE} E10332
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_START_X)}  Y{"Missing global variable PROBE_START_X"}   F{var.CURRENT_FILE} E10333
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_START_Y)}  Y{"Missing global variable PROBE_START_Y"}   F{var.CURRENT_FILE} E10334
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_OFFSET_Z)} Y{"Missing global variable PROBE_OFFSET_Z"}  F{var.CURRENT_FILE} E10335
; Checking if the XYUW are homed
var IS_NOT_HOMED = (!move.axes[0].homed || !move.axes[1].homed || (exists(move.axes[3].homed) && !move.axes[3].homed) || (exists(move.axes[4].homed) && !move.axes[4].homed) )
M98 P"/macros/assert/abort_if.g" R{var.IS_NOT_HOMED}  Y{"XYUW axes are required to be homed to home Z"}  F{var.CURRENT_FILE} 		E10336

; Definitions -----------------------------------------------------------------
var MOVEMENT_SPEED		= 10000		; [mm/min] Speed used in local moves
var Z_LIFT_SPEED		= 6000		; [mm/min] Speed used when lifting Z
var Z_LIFT				= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting
; Input parameters
var OMIT_REQUESTED = (exists(param.T) && param.T == 1)	

; Deselecting the current tool
if(state.currentTool != -1)
	T-1

if(var.OMIT_REQUESTED)
	G91			  	; relative positioning
	G1 H1 Z{var.Z_LIFT} F{var.Z_LIFT_SPEED}  	; lift Z relative to current position
G90			  		; absolute positioning

; Moving to the probe position
G1 X{global.PROBE_START_X} Y{global.PROBE_START_Y} F{var.MOVEMENT_SPEED}

; Saving the baby steps for later
var BABY_STEP = move.axes[2].babystep ; Saving the current baby step
M290 R0 S0 ; Setting babystep to 0
 
;G1 Z5 F{var.MOVEMENT_SPEED}
M400
; Homing with Z probe
M118 S"[HOMING] Homing with Z probe"
M98 P"/macros/probe/move_z_to_probe_position.g"

; We are in the probe height in Z
G92 Z{global.PROBE_OFFSET_Z} ; This value may be updated later in homeall.g
M400

if( network.name == "EMULATOR" )
	G4 S0.3   ; For the emulator to update the offset 

; Recover the baby stepping
M290 R0 S{var.BABY_STEP} ; Setting back the original babystep

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99 ; Proper exit