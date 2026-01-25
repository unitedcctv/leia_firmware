; Description: 	
;	The resume.g will be called when you resume a print.
;	In this the 
;		   - Set the printer to the relative extruder moves
;		   - Go  back to the last print position
;		   - relative extruder moves
;		   - extrude 10mm of filament
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE	= "/sys/resume.g"
M118 S{"[resume.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Changing the secondoray to resuming
set global.hmiStateDetail = "job_resuming"

if !exists(global.lastPrintingTool)
	global lastPrintingTool = state.currentTool

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"} F{var.CURRENT_FILE} E33600
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homexy.g"}  				F{var.CURRENT_FILE} E33601
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/recover_tool_temp.g"} F{var.CURRENT_FILE} E33603
; Checking the extruder is hot or not
M98 P"/macros/printing/recover_tool_temp.g"
; Setting the machine is print state ------------------------------------------
M98 P"/macros/printing/get_ready.g"
; Definitions
var TURN_OFF_TEMP = -273.1
var MIN_TEMP = 0
var FAST_XY_SPEED = 12000
; Home UW if needed ---------------------------------------------------------
;if global.toolPositioningFailed[0] || global.toolPositioningFailed[1]
;	M98 P"homeuw.g"
;	M400

; Homing XY if needed ---------------------------------------------------------
var NEEDS_HOMING_XY = !move.axes[0].homed || !move.axes[1].homed
if var.NEEDS_HOMING_XY
	M98 P"homexy.g"
M400

; turning off the idle tool if we are using relay
if(exists(global.activateExtruderRelay) && global.activateExtruderRelay)
	var idleTool = (global.lastPrintingTool == 0) ? 1 : 0
	M568 P{var.idleTool} S{var.MIN_TEMP} R{var.MIN_TEMP} A2
	M568 P{var.idleTool} S{var.TURN_OFF_TEMP} R{var.TURN_OFF_TEMP} A2
M116
; no need to wipe when resuming from wipe pause
if(!exists(global.manualWipe)|| !global.manualWipe)
	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T{global.lastPrintingTool} F1
M400
T{global.lastPrintingTool}
M400
; move to restore coordinates fast
;G1 X{state.restorePoints[1].coords[0]} F{var.FAST_XY_SPEED}
;G1 Y{state.restorePoints[1].coords[1]} F{var.FAST_XY_SPEED}
;M400
G29 S1 ; enable bed compensation
M400

; -----------------------------------------------------------------------------
M118 S{"[resume.g] Done "^var.CURRENT_FILE}
M99
