; Description:
;	The tool will be moved in the related axis (U/W) up or down depending
;	on the input value.
;	The tool to move is the current selected tool.
;   If a tool is specified by parameter, no movements will be done.
;	The offset will be stored in a vairable to be able to be recovered
;	later in the touch process.
; Input parameters:
;	- S: [mm] Offset in mm to move.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/axes/babystep_tool.g"
M118 S{"[babystep_tool.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/load.g"} 			F{var.CURRENT_FILE} E51100
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/save_number.g"} 	F{var.CURRENT_FILE} E51101
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/boards/get_index_in_om.g"} F{var.CURRENT_FILE} E51102
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.touchBedSensorBacklash)}	Y{"Missing global variable touchBedSensorBacklash"}					F{var.CURRENT_FILE} E51103
M98 P"/macros/assert/abort_if.g" R{#global.touchBedSensorBacklash<2} 			Y{"Global variable touchBedSensorBacklash needs to have length 2"}	F{var.CURRENT_FILE} E51104
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)} 			Y{"Missing input parameter S"} 	F{var.CURRENT_FILE} E51105
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)} 			Y{"Missing input parameter S"} 	F{var.CURRENT_FILE} E51106
M98 P"/macros/assert/abort_if_null.g" R{param.S} 				Y{"Input parameter S is null"}	F{var.CURRENT_FILE} E51107
M98 P"/macros/assert/abort_if.g" R{(state.currentTool == -1) && (!exists(param.T))} 	Y{"No tool selected and no Param.T provided"}			F{var.CURRENT_FILE} E51108

var TOOL = exists(param.T) ? param.T : state.currentTool

M98 P"/macros/assert/abort_if.g" R{global.touchBedSensorBacklash[var.TOOL] == null} Y{"Missing bed touch value for T%s"} A{state.currentTool,} F{var.CURRENT_FILE} E51109

; Definitions -----------------------------------------------------------------
var MIN_AXIS_ALLOWED	 	= 0					; [mm] Minimum allowed value in the axis
var STEP_SIZE			 	= param.S			; [mm] Step size

; Calculating the new position ------------------------------------------------
var MIN_AXIS_POSITION 			= move.axes[3+var.TOOL].min
var TARGET_MIN_AXIS_POSITION 	= var.MIN_AXIS_POSITION + var.STEP_SIZE

; Moving and changing the minimum position of the axis ------------------------
if(var.STEP_SIZE < 0)
	; Trying to change the current minimum position
	if(var.TARGET_MIN_AXIS_POSITION < var.MIN_AXIS_ALLOWED)
		M98 P"/macros/report/warning.g" Y"Unabled to change position: Too low" F{var.CURRENT_FILE} W51100
		M99 ; Not an abort as we may be printing
	if(var.TOOL == 0)
		M208 U{var.TARGET_MIN_AXIS_POSITION} S1  ; Setting the U minimum axis based on the result
	else
		M208 W{var.TARGET_MIN_AXIS_POSITION} S1
	M400
	; Now we move
	; First we move so we are not out of bounds
	var LIFTING_POSITION = {(var.TOOL == 0)?var.TARGET_MIN_AXIS_POSITION:move.axes[3].max,(var.TOOL == 1)?var.TARGET_MIN_AXIS_POSITION:move.axes[4].max}
	; only move if we change the active tool offset and not by param.T
	if (!exists(param.T))
		G1 U{var.LIFTING_POSITION[0]} W{var.LIFTING_POSITION[1]}
	M400
else
	if(var.TARGET_MIN_AXIS_POSITION >= move.axes[3+var.TOOL].max)
		M98 P"/macros/report/warning.g" Y"Unabled to change position: Too high" F{var.CURRENT_FILE} W51101
		M99 ; Not an abort as we may be printing
	; First we move so we are not out of bounds
	var START_POSITION = move.axes[3+var.TOOL].userPosition
	var LIFTING_POSITION = {(var.TOOL == 0)?var.TARGET_MIN_AXIS_POSITION:move.axes[3].max,(var.TOOL == 1)?var.TARGET_MIN_AXIS_POSITION:move.axes[4].max}
	; only move if we change the active tool offset and not by param.T
	if (!exists(param.T))
		; Wait until it changes
		while ( var.START_POSITION == move.axes[3+var.TOOL].userPosition)
			G1 U{var.LIFTING_POSITION[0]} W{var.LIFTING_POSITION[1]}
		M400
	M400
	; Trying to change the current minimum position
	if(var.TOOL == 0)
		M208 U{var.TARGET_MIN_AXIS_POSITION} S1  ; Setting the U minimum axis based on the result
	else
		M208 W{var.TARGET_MIN_AXIS_POSITION} S1
	M400

; Let's load the offset value -------------------------------------------------
; Find board with address
if( network.name != "EMULATOR" )
	var CAN_ADDRESS_TOOL 	= {81 + var.TOOL}
	M98 P"/macros/boards/get_index_in_om.g" A{var.CAN_ADDRESS_TOOL}
	M98 P"/macros/assert/abort_if_null.g" 	R{global.boardIndexInOM} Y{"Board not found"} F{var.CURRENT_FILE} E51111
var BOARD_INDEX = {( network.name != "EMULATOR" ) ? global.boardIndexInOM : 0 }
var BOARD_UUID  = boards[var.BOARD_INDEX].uniqueId	; Getting the Unique ID
; Getting the last offset value
; (!) WARNING: The names here listed need to match the names in the files:
;	- /sys/modules/stage/viio/v2/detect_bed_touch.g
var NEW_OFFSET 			= var.TARGET_MIN_AXIS_POSITION ; [mm] axis printing position


M118 S{"[babystep_tool.g] Updating touch sensor backlash to "^global.touchBedSensorBacklash}

set global.touchBedSensorBacklash[var.TOOL] = global.touchBedSensorBacklash[var.TOOL] + var.STEP_SIZE
M98 P"/macros/variable/save_number.g" N"global.touchBedSensorBacklash" V{global.touchBedSensorBacklash} C1

; -----------------------------------------------------------------------------
M118 S{"[babystep_tool.g] Done moving the tool "^var.TOOL^" "^var.STEP_SIZE^"mm"}
M99