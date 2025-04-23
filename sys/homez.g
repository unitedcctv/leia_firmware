; Description: 	
;   Homing Z routine with probe 
; Parameter: 
;   - T1: Homing from homeall.g, following homexy.g
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homez.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/move_z_to_probe_position.g"} F{var.CURRENT_FILE} E36200
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)}   Y{"Missing required module STAGE"}			F{var.CURRENT_FILE} E36201
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_START_X)}  Y{"Missing global variable PROBE_START_X"}   F{var.CURRENT_FILE} E36202
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_START_Y)}  Y{"Missing global variable PROBE_START_Y"}   F{var.CURRENT_FILE} E36203
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_OFFSET_Z)} Y{"Missing global variable PROBE_OFFSET_Z"}  F{var.CURRENT_FILE} E36204

; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}  	Y{"Missing global variable machineReadyToOperate"} 	  		F{var.CURRENT_FILE} E36205
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}  		Y{"Unexpected null value in global.machineReadyToOperate"} 	F{var.CURRENT_FILE} E36206
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}  			Y{"Unable to home as the emergency signal is active"} 	  	F{var.CURRENT_FILE} E36207

; Definitions -----------------------------------------------------------------
var MOVEMENT_SPEED		= 10000		; [mm/min] Speed used in local moves
var Z_LIFT_SPEED		= 6000		; [mm/min] Speed used when lifting Z
var Z_LIFT				= { (move.axes[2].min >= 0) ? 10 : (5 - move.axes[2].min)}		; [mm] Distance to move in Z before starting

; Process ---------------------------------------------------------------------
var errorMoving = false					; Used to record the result of a move.

M400	; Making sure the machine is not moving 

; Let's check if we need to abort
M98 P"/macros/printing/abort_if_forced.g" Y{"Starting the home to Zmin"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}

; Making sure the big motors are ON before moving -----------------------------
M17 X Y Z
G4 S0.5
M400

; Move Stage into position for Z homing
if (!exists(param.T) || (exists(param.T) && param.T != 1))
	M118 S"[HOMEZ] Lifting Z needed"
	if( !sensors.endstops[2].triggered )
		G91								; Relative position
		G1 H1 Z{var.Z_LIFT} F{var.Z_LIFT_SPEED}
		set var.errorMoving = (result > 0)
		M400
	else
		M98 P"/macros/report/warning.g" Y{"The Z endstop is triggered before moving"} F{var.CURRENT_FILE} W26200
	
	M98 P"/macros/printing/abort_if_forced.g" Y{"Before checking if tool lifters require home"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
	; Home UW if required
	if( !move.axes[3].homed || ( exists(move.axes[4]) && !move.axes[4].homed ) )
		M98 P"/sys/homeuw.g"
	M400
	T-1

	M98 P"/macros/printing/abort_if_forced.g" Y{"Before checking if XY require home"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
	; Home XY if required
	if( !move.axes[0].homed || !move.axes[1].homed )
		M98 P"homexy.g"
G90				; absolute positioning
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to lift Z"} F{var.CURRENT_FILE} 	E36208

M98 P"/macros/sensors/sanity_check.g" N"dist_bed_ball[um]" A{900.0} B{1500.0}
; Moving to probe position	
G1 X{global.PROBE_START_X} Y{global.PROBE_START_Y} F{var.MOVEMENT_SPEED}
set var.errorMoving = (result > 0)
M400
M98 P"/macros/assert/abort_if.g" R{var.errorMoving}  Y{"Unable to move XY into the probe position"} F{var.CURRENT_FILE} E36209

; Saving the baby steps and cleaning them.
var BABYSTEP_VALUE	  = move.axes[2].babystep ; save current babystep value
M290 R0 S0				; reset babystep value
M98  P"/macros/assert/result.g" R{result} Y"Unable to reset babysteps" F{var.CURRENT_FILE} E36210

M118 S"[HOMING] Start homing with Z Probe"
M400					; Making sure nothing is pending
G92 Z{move.axes[2].max}	; Setting the home position
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the new position in Z" F{var.CURRENT_FILE} E36211

; Moving down with the analog probe
M98 P"/macros/probe/move_z_to_probe_position.g"
G92 Z{global.PROBE_OFFSET_Z}
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the home position in Z" F{var.CURRENT_FILE} E36212
M400

; EMULATOR ONLY! 
if( network.name == "EMULATOR" )
	; For the emulator to update the offset 
	M308 S{global.PROBE_SENSOR_ID} ; Make sure the sensor zOffset is reloaded
	G4 S1
	M400

; Setting back the original babystep
M290 R0 S{var.BABYSTEP_VALUE}
M98  P"/macros/assert/result.g" R{result} Y"Unable to recover the babysteps" F{var.CURRENT_FILE} E36213

M98 P"/macros/report/event.g" Y"Home Z completed" F{var.CURRENT_FILE} V36200

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99