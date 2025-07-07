; Description:
;	This is file implements the bed mesh measurement.
;	File required by Duet3D. It is called when G32 is called.
; Example:
;	G32
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/bed.g"
M118 S{"[BEDMESH] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_BED)}  	Y{"Missing module BED"} F{var.CURRENT_FILE}  	E30001
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  	Y{"Missing module PROBES"} F{var.CURRENT_FILE}  E30002
M98 P"/macros/assert/abort_if.g" R{(!exists(heat.bedHeaters[0]))} 	Y{"No bed heater defined"} F{var.CURRENT_FILE} 	E30003

; Checking ig it is homed
var NOT_HOMED = ( !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed || (exists(move.axes[3].homed) && !move.axes[3].homed) || (exists(move.axes[4].homed) && !move.axes[4].homed) )
M98 P"/macros/assert/abort_if.g" R{var.NOT_HOMED}  Y{"Home required before running bed mesh"} F{var.CURRENT_FILE} 	E30004

; Definitions  ----------------------------------------------------------------
var MOVE_SPEED = 20000 		; [mm/min] Target speed while moving
var MARGIN_BBOX = 20		; [mm] if job bounding box exists we need a margin around bbox
var SPACING_MIN = 50
var MIN_NUM_POINTS_BED_MAP = 2 ;
var EXISTS_JOBBOX = exists(global.jobBBOX) && global.jobBBOX != null && #global.jobBBOX == 6
var bedMapPosX = {global.PROBE_START_X, global.printingLimitsX[1]}
var bedMapPosY = {global.PROBE_START_Y,global.printingLimitsY[1]}
var spacingBtwMapPoints = {100,42}

; Measurement -----------------------------------------------------------------

; Global variable to return the bed file.
if (exists(global.bedFile))	; Clear the return before calling 
	set global.bedFile = null

if(var.EXISTS_JOBBOX)
	; setting the margin for X and Y
	M118 S{"Job bounding box exists: Bed mapping only for bounding box"}
	var newMapPosX = {global.jobBBOX[0] - var.MARGIN_BBOX, global.jobBBOX[3] - var.MARGIN_BBOX}
	var newMapPosY = {global.jobBBOX[1] - var.MARGIN_BBOX ,global.jobBBOX[4] - var.MARGIN_BBOX}

	; checking the limits, keep old position if out of limits
	set var.newMapPosX[0] = (var.newMapPosX[0] > global.printingLimitsX[0]) ? var.newMapPosX[0] : global.printingLimitsX[0]
	set var.newMapPosX[1] = (var.newMapPosX[1] < global.printingLimitsX[1]) ? var.newMapPosX[1] : global.printingLimitsX[1]
	set var.newMapPosY[0] = (var.newMapPosY[0] > global.printingLimitsY[0]) ? var.newMapPosY[0] : global.printingLimitsY[0]
	set var.newMapPosY[1] = (var.newMapPosY[1] < global.printingLimitsY[1]) ? var.newMapPosY[1] : global.printingLimitsY[1]

	; calculating the width and the length
	var widthX = var.newMapPosX[1] - var.newMapPosX[0]
	var widthY = var.newMapPosY[1] - var.newMapPosY[0]
	
	set var.widthX = (var.widthX > 0) ? var.widthX : null
	set var.widthY = (var.widthY > 0) ? var.widthY : null
	if(var.widthX != null) && (var.widthY != null)
		set var.bedMapPosX = var.newMapPosX
		set var.bedMapPosY = var.newMapPosY
		var NUM_POINTS_X = max(var.MIN_NUM_POINTS_BED_MAP, var.widthX/var.SPACING_MIN)
		var NUM_POINTS_Y = max(var.MIN_NUM_POINTS_BED_MAP, var.widthY/var.SPACING_MIN)
		; calculating the spacing between the axes probing
		set var.spacingBtwMapPoints = {(var.widthX/var.NUM_POINTS_X) ,(var.widthY/var.NUM_POINTS_Y)}
	else
		M118 S{"Invalid job bounding box: continuing the full bed map"}


; setting the probe grid
M557 X{var.bedMapPosX} Y{var.bedMapPosY} S{var.spacingBtwMapPoints}
M400

; Process the result
var MESH_SUCCESS = ( exists(global.bedFile) && global.bedFile != null && global.bedFile != "" )
if( var.MESH_SUCCESS )
	; We need to load the bed map at Z0 and where we start.
	G29 S1
	M400
	G1 Z0 F{var.MOVE_SPEED}
	M98 P"/macros/report/event.g" Y{"Bed mapping completed, map available in: %s"} A{global.bedFile,} F{var.CURRENT_FILE} V30007
else
	M98 P"/macros/assert/abort.g" Y{"Bed mapping was not completed"}  F{var.CURRENT_FILE} E30006
M400

; -----------------------------------------------------------------------------
M118 S{"[BEDMESH] Done "^var.CURRENT_FILE}
M99 ; Proper exit