;   This script is in charge of homing all the axes available.
;   It is required by Duet3D and it is called when G28 is called without any
;   extra parameters.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/homeall.g"
M118 S{"[homeall.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{global.errorRestartRequired}  Y{"Previous error requires restart: Please restart the machine"} F{var.CURRENT_FILE} E35017
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homexy.g"}							F{var.CURRENT_FILE} E35002
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homez.g"}							 F{var.CURRENT_FILE} E35003
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"}  F{var.CURRENT_FILE} E35005
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/axes/home_to_zmax.g"}			  F{var.CURRENT_FILE} E35006
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/sanity_check.g"}			  F{var.CURRENT_FILE} E35014
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/xy_calibration/xy_calibration.g"} 		F{var.CURRENT_FILE} E35015
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}  Y{"Missing module AXES"}   F{var.CURRENT_FILE} E35007
M98 P"/macros/assert/abort_if.g" R{!exists(state.currentTool)}   Y{"In the OM, state.currentTool is missing"}   F{var.CURRENT_FILE} E35009
; Definitions -----------------------------------------------------------------
var Z_HOMING_FINAL_POS 	= 30					; [mm] Final position in Z
var MOVEMENT_SPEED 		= 10000					; [mm/min] Movement speed in this file.
var TIME_REHOMING_TO_Z_MAX = ( 60 * 60 * 24 ) 	; [sec] Max. time without re-homing to Zmax (24 hours)
; we cannot home to zmax if we are in sequential print, because we could crash with a part
; Ensure the X-axis printable limit upper bound is initialized to a numeric value
if (exists(global.printingLimitsX) && (global.printingLimitsX[1] == null))
	set global.printingLimitsX[1] = 1000

; Let's check the emergency and the sensor readings----------------------------
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}   Y{"Missing global variable machineReadyToOperate"}		  F{var.CURRENT_FILE} E35010
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}	   Y{"Unexpected null value in global.machineReadyToOperate"}  F{var.CURRENT_FILE} E35011
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}		   Y{"Unable to home as the emergency signal is active"}	   F{var.CURRENT_FILE} E35012


; First we need to disable the print area management so that the area is not shrunk if aborting during homing
if(!exists(global.activatePrintAreaManagement))
	global activatePrintAreaManagement = false
else
	set global.activatePrintAreaManagement = false

; Setting the default coordinate system
G54
M400

M98 P"/macros/printing/abort_if_forced.g" Y{"Before homing to Zmax"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
M98 P"/macros/axes/home_to_zmax.g"
M400
M18 Z ; Turn off Z motor to lose the position
; Update/set the last time homing to Zmax
if(!exists(global.homedToZmax))
	global homedToZmax = state.time
else
	set global.homedToZmax = state.time
M400

; get z min ----------------------------------------------------------------
; Get the probe ready
M401                       ; deploy BLTouch

; Fast plunge straight down 500 mm
G91                        ; relative moves
G1 H2 Z-400 F6000          ; ignore end-stops, ~100 mm s-¹
G90                        ; back to absolute coords

; Slow finish – probe down slowly until BLTouch triggers
M208 Z-650 S1
G30 S-1                    ; single probe, do not set Z, stops when probe triggers

; Record how far we are below the switch
var travel = -move.axes[2].machinePosition   ; positive number
echo "Total Z travel = "^{var.travel,2}," mm"

; Update soft limits so bed is Z-MIN = 0, switch is Z-MAX = travel  
M208 Z0 S1                 ; set new MIN at 0 (the bed)  :contentReference[oaicite:1]{index=1}
M208 Z{var.travel} S0      ; set new MAX at measured travel  :contentReference[oaicite:2]{index=2}

; Re-zero (already at the bed) and tidy up
G92 Z0                     ; current spot *is* Z 0 from now on
M402                       ; retract BLTouch

; Move XY to final positions --------------------------------------------------
G1 X{var.FINAL_POSITION[0]} Y{var.FINAL_POSITION[1]} F{var.MOVEMENT_SPEED}
M400


M118 S{"[homeall.g] Axes homed"}

; -----------------------------------------------------------------------------
M118 S{"[homeall.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit