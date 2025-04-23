; Description: 	
;	Move axes relative to current position
;	   Input parameter:
;		 X : Amount of X movement in mm
;		 Y : Amount of Y movement in mm
;		 Z : Amount of Z movement in mm 
;		 F : Feedrate in mm/min
; Example:
; 	M98 P"/macros/hmi/relative_move.g" X60 Y15 Z10
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/axes/move/relative.g"
M118 S{"[relative.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking if any file missing
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"}  F{var.CURRENT_FILE} E80320
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsX)}	Y{"Missing global.printingLimitsX"}	F{var.CURRENT_FILE} E80301
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsX < 2}	Y{"length of global.printingLimitsX < 2"}	F{var.CURRENT_FILE} E80302
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsY)}	Y{"Missing global.printingLimitsY"}	F{var.CURRENT_FILE} E80303
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsY < 2}	Y{"length of global.printingLimitsY < 2"}	F{var.CURRENT_FILE} E80304
M98 P"/macros/assert/abort_if.g" R{!exists(global.printingLimitsZ)}	Y{"Missing global.printingLimitsZ"}	F{var.CURRENT_FILE} E80305
M98 P"/macros/assert/abort_if.g" R{#global.printingLimitsZ < 2}	Y{"length of global.printingLimitsZ < 2"}	F{var.CURRENT_FILE} E80306
; Input parameters 
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)}	Y{"Missing required parameter F"}	F{var.CURRENT_FILE} E80317
M98 P"/macros/assert/abort_if_null.g" R{param.F}	Y{"Param F is null"}	F{var.CURRENT_FILE} E80318
M98 P"/macros/assert/abort_if.g" R{param.F < 1}	Y{"Parameter F needs to be > 0"}	F{var.CURRENT_FILE} E80319
; Let's check the emergency
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}   Y{"Missing global variable machineReadyToOperate"}		  F{var.CURRENT_FILE} E80321
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}	   Y{"Unexpected null value in global.machineReadyToOperate"}  F{var.CURRENT_FILE} E80322
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}		   Y{"Unable to home as the emergency signal is active"}	   F{var.CURRENT_FILE} E80323
; Definitions -----------------------------------------------------------------
var X_MAX_POS = global.printingLimitsX[1]
var X_MIN_POS = global.printingLimitsX[0]
var X_CURR_POS = move.axes[0].userPosition
var xReqPos = var.X_CURR_POS
var Y_MAX_POS = global.printingLimitsY[1]
var Y_MIN_POS = global.printingLimitsY[0]
var Y_CURR_POS = move.axes[1].userPosition
var yReqPos = var.Y_CURR_POS
var Z_MAX_POS = global.printingLimitsZ[1]
var Z_MIN_POS = global.printingLimitsZ[0]
var Z_CURR_POS = move.axes[2].userPosition
var zReqPos = var.Z_CURR_POS

; Proceed to start a print ----------------------------------------------------
; checking the params limits first
if(exists(param.X))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.xReqPos}	Y{"Param X is null"} F{var.CURRENT_FILE} E80307
	var TARGET_X = var.X_CURR_POS + param.X
	if(var.TARGET_X < var.X_MIN_POS)
		M98 P"/macros/report/warning.g" 	Y{"X clamped to printing minimum"} F{var.CURRENT_FILE} W80308
		set var.xReqPos = var.X_MIN_POS
	elif(var.TARGET_X > var.X_MAX_POS)
		M98 P"/macros/report/warning.g" 	Y{"X clamped to printing maximum"} F{var.CURRENT_FILE} W80309
		set var.xReqPos = var.X_MAX_POS
	else
		set var.xReqPos = var.TARGET_X

if(exists(param.Y))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.yReqPos}	Y{"Param Y is null"} F{var.CURRENT_FILE} E80310
	var TARGET_Y = var.Y_CURR_POS + param.Y
	if(var.TARGET_Y < var.Y_MIN_POS)
		M98 P"/macros/report/warning.g" 	Y{"Y clamped to printing minimum"} F{var.CURRENT_FILE} W80311
		set var.yReqPos = var.Y_MIN_POS
	elif(var.TARGET_Y > var.Y_MAX_POS)
		M98 P"/macros/report/warning.g" 	Y{"Y clamped to printing maximum"} F{var.CURRENT_FILE} W80312
		set var.yReqPos = var.Y_MAX_POS
	else
		set var.yReqPos = var.TARGET_Y

if(exists(param.Z))
	M98 P"/macros/assert/abort_if_null.g" 	R{var.zReqPos}	Y{"Param Z is null"} F{var.CURRENT_FILE} E80313
	var TARGET_Z = var.Z_CURR_POS + param.Z
	if(var.TARGET_Z < var.Z_MIN_POS)
		M98 P"/macros/report/warning.g" 	Y{"Z clamped to printing minimum"} F{var.CURRENT_FILE} W80314
		set var.zReqPos = var.Z_MIN_POS
	elif(var.TARGET_Z > var.Z_MAX_POS)
		M98 P"/macros/report/warning.g" 	Y{"Z clamped to printing maximum"} F{var.CURRENT_FILE} W80315
		set var.zReqPos = var.Z_MAX_POS
	else
		set var.zReqPos = var.TARGET_Z

; Proceed to move to the axes to requested position------------------------------
G1 F{param.F} X{var.xReqPos} Y{var.yReqPos} Z{var.zReqPos}
M98  P"/macros/assert/result.g" R{result} Y{"Unable to move the axes to requested position"} F{var.CURRENT_FILE} E80316
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[relative.g] Done "^var.CURRENT_FILE}
M99
