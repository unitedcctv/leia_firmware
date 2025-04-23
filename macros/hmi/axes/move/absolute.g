
; Description: 	
;	Move axes to absolute position
;       Input parameter:
;         X : Amount of X movement in mm
;         Y : Amount of Y movement in mm
;         Z : Amount of Z movement in mm
;         F : Feedrate in mm/min
; Example:
; 	M98 P"/macros/hmi/absolute_move.g" X60 Y15 Z10
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/axes/move/absolute.g"
M118 S{"[absolute.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking if any file missing
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"}  F{var.CURRENT_FILE} E80220

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsX)}    Y{"Missing global.printingLimitsX"}    F{var.CURRENT_FILE} E80201
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsX < 2}    Y{"length of global.printingLimitsX < 2"}    F{var.CURRENT_FILE} E80202
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsY)}    Y{"Missing global.printingLimitsY"}    F{var.CURRENT_FILE} E80203
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsY < 2}    Y{"length of global.printingLimitsY < 2"}    F{var.CURRENT_FILE} E80204
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsZ)}    Y{"Missing global.printingLimitsZ"}    F{var.CURRENT_FILE} E80205
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsZ < 2}    Y{"length of global.printingLimitsZ < 2"}    F{var.CURRENT_FILE} E80206
; Input parameters 
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)}    Y{"Missing required parameter F"}    F{var.CURRENT_FILE} E80217
M98 P"/macros/assert/abort_if_null.g" R{param.F}    Y{"Param F is null"}    F{var.CURRENT_FILE} E80218
M98 P"/macros/assert/abort_if.g" R{param.F < 1}    Y{"Parameter F needs to be > 0"}    F{var.CURRENT_FILE} E80219
; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}   Y{"Missing global variable machineReadyToOperate"}		  F{var.CURRENT_FILE} E80221
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}	   Y{"Unexpected null value in global.machineReadyToOperate"}  F{var.CURRENT_FILE} E80222
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}		   Y{"Unable to home as the emergency signal is active"}	   F{var.CURRENT_FILE} E80223
; Definitions -----------------------------------------------------------------
var X_MAX_POS = global.printingLimitsX[1]
var X_MIN_POS = global.printingLimitsX[0]
var xReqPos = move.axes[0].userPosition
var Y_MAX_POS = global.printingLimitsY[1]
var Y_MIN_POS = global.printingLimitsY[0]
var yReqPos = move.axes[1].userPosition
var Z_MAX_POS = global.printingLimitsZ[1]
var Z_MIN_POS = global.printingLimitsZ[0]
var zReqPos = move.axes[2].userPosition

; Proceed to start a print ----------------------------------------------------
; checking the params limits first
if(exists(param.X))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.xReqPos}	Y{"Param X is null"} F{var.CURRENT_FILE} E80207
	if(param.X < var.X_MIN_POS)
		M98 P"/macros/assert/abort.g" 	Y{"X target position below axis minimum"} F{var.CURRENT_FILE} E80208
	elif(param.X > var.X_MAX_POS)
		M98 P"/macros/assert/abort.g" 	Y{"X target position above axis maximum"} F{var.CURRENT_FILE} E80209
	set var.xReqPos = param.X

if(exists(param.Y))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.yReqPos}	Y{"Param Y is null"} F{var.CURRENT_FILE} E80210
	if(param.Y < var.Y_MIN_POS)
		M98 P"/macros/assert/abort.g" 	Y{"Y target position below axis minimum"} F{var.CURRENT_FILE} E80211
	elif(param.Y > var.Y_MAX_POS)
		M98 P"/macros/assert/abort.g" 	Y{"Y target position above axis maximum"} F{var.CURRENT_FILE} E80212
	set var.yReqPos = param.Y

if(exists(param.Z))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.zReqPos}	Y{"Param Z is null"} F{var.CURRENT_FILE} E80213
	if(param.Z < var.Z_MIN_POS)
		M98 P"/macros/assert/abort.g" 	Y{"Z target position below axis minimum"} F{var.CURRENT_FILE} E80214
	elif(param.Z > var.Z_MAX_POS)
		M98 P"/macros/assert/abort.g" 	Y{"Z target position above axis maximum"} F{var.CURRENT_FILE} E80215
	set var.zReqPos = param.Z

; Proceed to move to the axes to requested position------------------------------
G1 F{param.F} X{var.xReqPos} Y{var.yReqPos} Z{var.zReqPos}
M98  P"/macros/assert/result.g" R{result} Y{"Unable to move the axes to requested position"} F{var.CURRENT_FILE} E80216

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[absolute.g] Done "^var.CURRENT_FILE}
M99
