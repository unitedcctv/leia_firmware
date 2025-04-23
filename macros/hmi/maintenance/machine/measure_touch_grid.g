;---------------------------------------------------------------------------------------------
; Description:
;	This macro measures a grid of points using detect_bed_touch.g and saves the results to a CSV file.
;   It allows for comparison between bedmap of the ball sensor as well as the nozzle.
; Parameters:
; 	- T: Tool(s) to use (tool number or 2=both), default all installed
; 	- X: Number of points in X, default 5
; 	- Y: Number of points in Y, default 3
;---------------------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/hmi/maintenance/machine/measure_touch_grid.g"
M118 S{"[measure_touch_grid.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check dependencies
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/stage/detect_bed_touch.g"} F{var.CURRENT_FILE} E89021
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/lock.g"} F{var.CURRENT_FILE} E89022
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/doors/unlock.g"} F{var.CURRENT_FILE} E89023

; lock the door----------------------------------------------------------------
M98 P"/macros/doors/lock.g"

var AXES_HOMED = move.axes[0].homed && move.axes[1].homed && move.axes[2].homed && move.axes[3].homed && move.axes[4].homed
if (!var.AXES_HOMED)
	G28
M400

var USE_T0 = exists(tools[0]) && tools[0] != null
var USE_T1 = exists(tools[1]) && tools[1] != null

if exists(param.T)
	set var.USE_T0 = var.USE_T0 && ((param.T == 0 || param.T == 2))
	set var.USE_T1 = var.USE_T1 && ((param.T == 1 || param.T == 2))

var NUM_X = exists(param.X) ? param.X : 10
var NUM_Y = exists(param.Y) ? param.Y : 5

var MIN_X = global.printingLimitsX[0]
var MIN_Y = global.printingLimitsY[0]
var MAX_X = global.printingLimitsX[1]
var MAX_Y = global.printingLimitsY[1]

var ix = 0
var iy = 0

var printHeaders = 1
var LOGFILE = "/sys/logs/touchgrid/touchgrid"^+state.time^".csv"
M118 S{"[measure_touch_grid.g] Logfile: "^var.LOGFILE}

while var.iy < var.NUM_Y
	var Y = var.MIN_Y + (var.MAX_Y - var.MIN_Y) / (var.NUM_Y - 1) * var.iy
	var X = var.MIN_X
	while var.ix < var.NUM_X
		set var.X = var.MIN_X + (var.MAX_X - var.MIN_X) / (var.NUM_X - 1) * var.ix
		M118 S{"[measure_touch_grid.g] Measuring touch grid at X:"^var.X^" Y:"^var.Y}
		if var.USE_T0
			M98 P"/macros/stage/detect_bed_touch.g" T0 X{var.X} Y{var.Y} W0 F{var.LOGFILE} H{var.printHeaders} B1 ; only one probe per point
			set var.printHeaders = 0
		M400
		if var.USE_T1
			M98 P"/macros/stage/detect_bed_touch.g" T1 X{var.X} Y{var.Y} W0 F{var.LOGFILE} H{var.printHeaders} B1 ; only one probe per point
			set var.printHeaders = 0
		M400
		M98 P"/macros/printing/abort_if_forced.g" Y{"While measuring touch grid"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
		set var.ix = var.ix + 1
	M400
	set var.iy = var.iy + 1
	set var.ix = 0
M400

; unlock the door----------------------------------------------------------------
M98 P"/macros/doors/unlock.g"

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------
M118 S{"[measure_touch_grid.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit