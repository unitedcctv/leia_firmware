
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
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homeuw.g"}							F{var.CURRENT_FILE} E35001
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homexy.g"}							F{var.CURRENT_FILE} E35002
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/homez.g"}							 F{var.CURRENT_FILE} E35003
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/stage/detect_bed_touch.g"}		 F{var.CURRENT_FILE} E35004
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"}  F{var.CURRENT_FILE} E35005
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/axes/home_to_zmax.g"}			  F{var.CURRENT_FILE} E35006
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/sanity_check.g"}			  F{var.CURRENT_FILE} E35014
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/xy_calibration/xy_calibration.g"} 		F{var.CURRENT_FILE} E35015
; Checking modules and global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_AXES)}  Y{"Missing module AXES"}   F{var.CURRENT_FILE} E35007
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_STAGE)} Y{"Missing module STAGE"}  F{var.CURRENT_FILE} E35008
M98 P"/macros/assert/abort_if.g" R{!exists(state.currentTool)}   Y{"In the OM, state.currentTool is missing"}   F{var.CURRENT_FILE} E35009
; Definitions -----------------------------------------------------------------
var Z_HOMING_FINAL_POS 	= 30					; [mm] Final position in Z
var MOVEMENT_SPEED 		= 10000					; [mm/min] Movement speed in this file.
var TIME_REHOMING_TO_Z_MAX = ( 60 * 60 * 24 ) 	; [sec] Max. time without re-homing to Zmax (24 hours)
; we cannot home to zmax if we are in sequential print, because we could crash with a part
var IN_SEQUENTIAL_PRINT = exists(global.printingLimitsX) && (global.printingLimitsX[1] < 1000)
var NEEDS_HOME_Z_MAX = !exists(global.homedToZmax) || (exists(global.homedToZmax) && ((state.time - global.homedToZmax) > var.TIME_REHOMING_TO_Z_MAX))
set var.NEEDS_HOME_Z_MAX = var.NEEDS_HOME_Z_MAX && !var.IN_SEQUENTIAL_PRINT
; Let's check the emergency and the sensor readings----------------------------
M98 P"/macros/emergency/is_ready_to_operate.g"
M98 P"/macros/assert/abort_if.g" R{!exists(global.machineReadyToOperate)}   Y{"Missing global variable machineReadyToOperate"}		  F{var.CURRENT_FILE} E35010
M98 P"/macros/assert/abort_if_null.g" R{global.machineReadyToOperate}	   Y{"Unexpected null value in global.machineReadyToOperate"}  F{var.CURRENT_FILE} E35011
M98 P"/macros/assert/abort_if.g" R{!global.machineReadyToOperate}		   Y{"Unable to home as the emergency signal is active"}	   F{var.CURRENT_FILE} E35012

; Local variables -------------------------------------------------------------
var STANDBY_TEMP_OFFSET = 20
; we are starting a print
var STARTING_PRINT = {state.status == "processing" && job.file.fileName != null}
M118 S{"[homeall.g] Starting print: " ^ var.STARTING_PRINT}
var RESUMING_PRINT = {(state.status == "paused" || state.status == "resuming") && job.file.fileName != null}
M118 S{"[homeall.g] Resuming print: " ^ var.RESUMING_PRINT}

var currentTool = state.currentTool
var TOOL_TURN_OFF_TEMP = -273.1
var activeTemps = vector(#tools, var.TOOL_TURN_OFF_TEMP)
var standbyTemps = vector(#tools, var.TOOL_TURN_OFF_TEMP)
var hotTools = vector(#tools, false)
var bothToolsHot = false
; setting the temperature control variables
if (!exists(tools) || (#tools > 2))
	M118 S{"[homeall.g] Unsupported number of tools" ^ exists(tools) ? #tools : 0}
else
	while iterations < #tools
		if (exists(tools[iterations]))
			var activeTemp = tools[iterations].active[0]
			var standbyTemp = tools[iterations].standby[0]
				if var.activeTemp > 0
					set var.activeTemps[iterations] = var.activeTemp
					; for compatibility, we are setting an offset standby temperature if it is not different from the active temperature
					set var.standbyTemps[iterations] = var.activeTemp != var.standbyTemp ? var.standbyTemp : (var.activeTemp - var.STANDBY_TEMP_OFFSET)
					set var.hotTools[iterations] = true
				if (var.STARTING_PRINT)
					; set target temperature to standby
					M568 P{iterations} R{var.standbyTemps[iterations]} S{var.standbyTemps[iterations]} A2
	M400
M400

set var.bothToolsHot = #var.hotTools > 1 && var.hotTools[0] && var.hotTools[1]

if(!exists(global.lastPrintingTool))
	global lastPrintingTool = var.currentTool
else
	set global.lastPrintingTool = var.currentTool

if(var.STARTING_PRINT)
	set global.hmiStateDetail = "job_calib_homing"

; First we need to disable the print area management so that the area is not shrunk if aborting during homing
if(!exists(global.activatePrintAreaManagement))
	global activatePrintAreaManagement = false
else
	set global.activatePrintAreaManagement = false

; Setting the default coordinate system
G54
M400

; check if the override tool exists then use the override tool------------------
if (var.STARTING_PRINT)
	if (exists(global.overrideExtruderNum) && (global.overrideExtruderNum != null) && (global.overrideExtruderNum != var.currentTool) )
		M98 P"/macros/assert/abort_if.g" R{var.bothToolsHot} Y{"Dual extrusion print: Cannot start the print with override extruder"} F{var.CURRENT_FILE} E35113
		; copy temperatures to override tool and turn off the old tool
		var NEW_TOOL = global.overrideExtruderNum
		set var.activeTemps[var.NEW_TOOL] = var.activeTemps[var.currentTool]
		set var.standbyTemps[var.NEW_TOOL] = var.standbyTemps[var.currentTool]
		set var.activeTemps[var.currentTool] = var.TOOL_TURN_OFF_TEMP
		set var.standbyTemps[var.currentTool] = var.TOOL_TURN_OFF_TEMP
		; heat override tool
		M568 P{var.NEW_TOOL} R{var.standbyTemps[var.NEW_TOOL]} S{var.standbyTemps[var.NEW_TOOL]} A2
		; turn off the old tool
		M568 P{var.currentTool} R{var.TOOL_TURN_OFF_TEMP} S{var.TOOL_TURN_OFF_TEMP} A2

		set var.hotTools = vector(#tools, false)
		set var.hotTools[var.NEW_TOOL] = true
		set var.currentTool = var.NEW_TOOL
	M400
M400

T-1 ; Deselect the current extruder

; home only lifters for connected extruders ----------------------------------------
if exists(global.MODULE_EXTRUDER_0) && exists(global.MODULE_EXTRUDER_1)
	M98 P"/sys/homeuw.g"
elif exists(global.MODULE_EXTRUDER_0)
	M98 P"/sys/homeu.g"
elif exists(global.MODULE_EXTRUDER_1)
	M98 P"/sys/homew.g"
M400

; Clean the homing of XY ------------------------------------------------------
M18 X Y ; Turn off XY motors to lose the position
M400

if (!var.RESUMING_PRINT)
	if(var.NEEDS_HOME_Z_MAX)
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
M400

; Homing the Axes -------------------------------------------------------------
; Homing XY first if required
M98 P"/macros/printing/abort_if_forced.g" Y{"Before homing XY"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
if( !move.axes[0].homed || !move.axes[1].homed )
	M98 P"/sys/homexy.g"
M400

; Homing to Zmin if needed ---------------------------------------------------
if(!move.axes[2].homed)
	G29 S2 ; disable heightmap before homing z
	; abort if we are resuming a print but need to home Z
	M98 P"/macros/assert/abort_if.g" R{var.RESUMING_PRINT} Y{"Z Axis lost position. Cannot resume print!"} F{var.CURRENT_FILE} E35016
	M598
	M98 P"/sys/homez.g" T1 ; T1 for homing from homeall.g
	M400
	G90 ; Absolute position
	G1 Z0 F{var.MOVEMENT_SPEED}
M400
G90 ; Absolute position

M118 S{"[homeall.g] Axes homed"}

; Bed leveling ----------------------------------------------------------------
var OMIT_BED_LEVELING = ( exists(global.omitBedLeveling) && global.omitBedLeveling == true )
; Procedures to run only if we are starting a print ---------------------------
if (var.STARTING_PRINT)

	if( var.OMIT_BED_LEVELING )
		set global.omitBedLeveling = false ; Disable this only once flag
		M118 S"[homeall.g] Omitting bed mapping"
	else
		; wipe
		if(global.wiperPresent)
			G1 Z5 F{var.MOVEMENT_SPEED}
			M400
			M98 P"/macros/nozzle_cleaner/wipe.g" T{var.currentTool} F0
		M400

		set global.hmiStateDetail = "job_calib_mapping"
		G32
	M400

	G90 ; Absolute position

	; set both extruders to their printing temps
	while iterations < #tools
		if (exists(tools[iterations]) && var.hotTools[iterations])
			var TOOL = tools[iterations].number
			M568 P{var.TOOL} R{var.activeTemps[iterations]} S{var.activeTemps[iterations]} A2
		M400
	M400

	; Set print location if we have a bounding box ---------------------------------
	; Printer will move to that location before reselecting the extruder and starting the print
	; This avoids a crash if the tool is too low after homing

	var boxX = 0
	var boxY = 0
	var firstLayerHeight = 0
	if (exists(global.jobBBOX) && global.jobBBOX != null && #global.jobBBOX == 6)

		if (global.jobBBOX[0] > global.printingLimitsX[0] && global.jobBBOX[0] < global.printingLimitsX[1])
			set var.boxX = global.jobBBOX[0]
		if (global.jobBBOX[1] > global.printingLimitsY[0] && global.jobBBOX[1] < global.printingLimitsY[1])
			set var.boxY = global.jobBBOX[1]
		if (global.jobBBOX[2] != null && global.jobBBOX[2] > 0)
			set var.firstLayerHeight = global.jobBBOX[2]

	; -------------------------------------------------------------------------
	; Bed Touch Calibration ---------------------------------------------------
	; -------------------------------------------------------------------------
	var OMIT_BED_TOUCH_REQUESTED = (exists(global.omitBedTouch) && global.omitBedTouch == true )

	while iterations < #tools
		if (exists(tools[iterations]) && var.hotTools[iterations])
			var TOOL = tools[iterations].number
			M98 P"/macros/printing/abort_if_forced.g" Y{"Before bed touch calibration T"^var.TOOL} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
			; Bed touch has been done before and we have a persistent variable
			var BED_TOUCH_DONE = global.touchBedCalibrations[var.TOOL] != null
			if( var.OMIT_BED_TOUCH_REQUESTED && var.BED_TOUCH_DONE )
				M118 S{"[homeall.g] Omitting bed touch T"^var.TOOL}
				continue
			M400
			set global.hmiStateDetail = "job_calib_bedtouch"
			M118 S{"[homeall.g] Running bed touch for tool: "^var.TOOL}
			; set the tool to the printing temperature for touch calibration
			M568 P{var.TOOL} R{var.activeTemps[iterations]} S{var.activeTemps[iterations]} A2
			M98 P"/macros/stage/detect_bed_touch.g" T{var.TOOL} K0
			M400
			; cool tool back down to standby temperature
			M568 P{var.TOOL} R{var.standbyTemps[iterations]} S{var.standbyTemps[iterations]} A2
		else
			M118 S{"[homeall.g] T"^iterations^" cold or not available, skipping bed touch"}
		M400
	M400
	if(global.bedCompensationActive)
		G29 S1 ; enable heightmap after calibrating Touch
		M376 H5 ; set bed compensation tapering to 5mm
	M400
	; reselect the tool active before homing
	if(var.currentTool >= 0 && move.axes[2].machinePosition < 1)
		; move above the bed so that we can select the extruder
		G1 Z1 F{var.MOVEMENT_SPEED}
		G1 X0 Y0 F{var.MOVEMENT_SPEED}
	M400

	; -------------------------------------------------------------------------
	; Extruder Relay ----------------------------------------------------------
	; if we want relay enabled we need to mirror the tool temperatures of both extruders before doing XY calibration.
	; This will cause XY calibration to be done for both extruders, just like in a Dual Extrusion print
	; -------------------------------------------------------------------------

	var RELAY_REQUESTED = (exists(global.activateExtruderRelay) && global.activateExtruderRelay == true)
	if (var.RELAY_REQUESTED)
		; check if we are in a dual extrusion print
		if(var.bothToolsHot)
			M98 P"/macros/report/warning.g" Y{"Dual extrusion print is running, cannot activate the extruder relay"}  	F{var.CURRENT_FILE} W12829
			set global.activateExtruderRelay = false
		else
			var RELAY_TOOL = var.currentTool == 0 ? 1 : 0
			set var.activeTemps[var.RELAY_TOOL] = var.activeTemps[var.currentTool]
			set var.standbyTemps[var.RELAY_TOOL] = var.standbyTemps[var.currentTool]

			set var.bothToolsHot = true
		M400
	M400

	; -------------------------------------------------------------------------
	; XY Calibration ----------------------------------------------------------
	; -------------------------------------------------------------------------
	var OMIT_XY_CALIBRATION = (var.OMIT_BED_TOUCH_REQUESTED || (exists(global.omitXYCalibration) && global.omitXYCalibration == true) )
	if( !var.OMIT_XY_CALIBRATION && var.bothToolsHot)
		set global.hmiStateDetail = "job_calib_xy"
		M98 P"/macros/xy_calibration/xy_calibration.g" T{var.activeTemps[0], var.standbyTemps[0], var.activeTemps[1], var.standbyTemps[1]}
		M400
	M400

	; recover tool temps
	while iterations < #tools
		if exists(tools[iterations])
			var TOOL = tools[iterations].number
			if (iterations == var.currentTool)
				; set the tool to the printing temperature if it's the currently active one
				M568 A2 P{iterations} R{var.activeTemps[iterations]} S{var.activeTemps[iterations]}
			elif var.RELAY_REQUESTED
				M568 A2 P{iterations} R{var.TOOL_TURN_OFF_TEMP} S{var.TOOL_TURN_OFF_TEMP}
			else
				; set the tool to the standby temperature if it's not the currently active one
				M568 A2 P{iterations} R{var.standbyTemps[iterations]} S{var.standbyTemps[iterations]}
			M400

	; wait for current tool to reach printing temperature
	M116 P{var.currentTool} S5
	M400
	; wipe
	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T{var.currentTool} F1
	M400
	; move up Z before travelling to the print location
	G1 Z5 F{var.MOVEMENT_SPEED}
	G1 X{var.boxX} Y{var.boxY} F{var.MOVEMENT_SPEED}
	M400

	; homing is successful, we activate print area management again
	set global.activatePrintAreaManagement = true
	; flag to know the homing status for print area management
	if(exists(global.homingDone))
		set global.homingDone = true

	T{var.currentTool}
M400
; Print start procedures finished ----------------------------------------------

if (job.file.fileName != null)
	; Setting back to the workplace coordinate system if we're in a print
	M118 S{"[homeall.g] Switching to workplace coordinate system"}
	G55
	M400
M400

; -----------------------------------------------------------------------------
M118 S{"[homeall.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit