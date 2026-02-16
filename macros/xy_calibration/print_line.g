; Description:  
;	Print the XY calibration pattern. 
; Input parameters: 
;	- X: [mm] Position of the pattern
; 	- L: [mm] Line length
;	- H: [mm] Line height
;	- F: Folder name
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/print_line.g"
M118 S{"[print_line.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/save_number.g"} 				E69050
; Checking input parameters
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  	Y{"Missing modules PROBES"} 			F{var.CURRENT_FILE}	E69051
M98 P"/macros/assert/abort_if.g" R{(state.currentTool == -1)}  	   	Y{"No tool selected"}					F{var.CURRENT_FILE} E69052
M98 P"/macros/assert/abort_if.g" R{!exists(param.X)} 				Y{"Missing required input parameter X"} F{var.CURRENT_FILE} E69053
M98 P"/macros/assert/abort_if_null.g" R{param.X}  	 				Y{"Input parameter X is null"} 		 	F{var.CURRENT_FILE} E69054
M98 P"/macros/assert/abort_if.g" R{!exists(param.L)} 				Y{"Missing required input parameter L"} F{var.CURRENT_FILE} E69055
M98 P"/macros/assert/abort_if_null.g" R{param.L}  	 				Y{"Input parameter L is null"} 		 	F{var.CURRENT_FILE} E69056
M98 P"/macros/assert/abort_if.g" R{!exists(param.H)} 				Y{"Missing required input parameter H"} F{var.CURRENT_FILE} E69057
M98 P"/macros/assert/abort_if_null.g" R{param.H}  	 				Y{"Input parameter H is null"} 		 	F{var.CURRENT_FILE} E69058
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)} 				Y{"Missing required input parameter F"} F{var.CURRENT_FILE} E69059
M98 P"/macros/assert/abort_if_null.g" R{param.F}  	 				Y{"Input parameter F is null"} 		 	F{var.CURRENT_FILE} E69060
M98 P"/macros/assert/abort_if.g" R{!exists(param.A)} 				Y{"Missing required input parameter A"} F{var.CURRENT_FILE} E69061
M98 P"/macros/assert/abort_if_null.g" R{param.A}  	 				Y{"Input parameter A is null"} 		 	F{var.CURRENT_FILE} E69062


; Check machine conditions
var IS_NOT_HOMED = (!move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed )
M98 P"/macros/assert/abort_if.g" R{var.IS_NOT_HOMED}  Y{"Home required before executing xy-calibration"}  F{var.CURRENT_FILE} E69070

; Definitions -----------------------------------------------------------------
var SPEED_FAST_MOVE 	= 12000							; [mm/min] Fast move speed
var SPEED_PRINT 		= 900							; [mm/min] Print move speed
var EXTRA_LINES 		= 2
var X_MARGIN 			= 10							; [mm] Margins in X 
var DEFAULT_LINE_LENGTH = (var.X_MARGIN*var.EXTRA_LINES); [mm] Length of one calibration line
var X_EXTRA_LENGTH 		= 5								; [mm] add a piece extra to the x line so that there is no "sollbruchstelle" between the line end and the purge pattern
var DEFAULT_LINE_HEIGHT = 0.4							; [mm] Height of calibration lines
var LINE_WIDTH 			= 0.8							; [mm] Width of calibration lines
var MEASURE_LENGTH 		= 18	  						; [mm] Measurement distance
var EXTRUSION_ADJUST	= 1.1							; [] Value to adjust the extrusion
var FILAMENT_SECTION 	= 3.14 * (2.85/2) * (2.85/2) 	; [mm2] Extrusion
; Print prime patter
var DEFAULT_SIDE_LENGTH = 15
var LENGTH_INCREASE = 0.6

; (!) This path is shared between others xy_calibration g-codes
var PARAMETER_PATH = param.A

; Getting the input arguments -------------------------------------------------
var SIDE_LENGTH = { (param.L != 0) ? param.L : var.DEFAULT_SIDE_LENGTH }
var LINE_HEIGHT = { (param.H != 0) ? param.H : var.DEFAULT_LINE_HEIGHT }
var BOUNDING_POSITION = param.X

; Calculation of required parameters ------------------------------------------
var EXTRUSION_FACTOR 	= {var.EXTRUSION_ADJUST * (var.LINE_HEIGHT * var.LINE_WIDTH) / var.FILAMENT_SECTION}	; [] Extrusion factor
; Set bounding box dimensions -------------------------------------------------
var BOUNDING_DIM = { var.SIDE_LENGTH , var.SIDE_LENGTH + 2*var.MEASURE_LENGTH}
M118 S{"[XYCAL] Bounding dimensions: "^var.BOUNDING_DIM^" mm"}

; Extrusion -------------------------------------------------------------------
M118 S{"[XYCAL] Using an extrusion factor of: "^var.EXTRUSION_FACTOR}
; Move to start position
G1 X{var.BOUNDING_POSITION[0]} Y{var.BOUNDING_POSITION[1]} F{var.SPEED_FAST_MOVE}
G1 Z{var.LINE_HEIGHT} F{var.SPEED_FAST_MOVE}
;Prime: print in snake pattern for as long till the extrusion length is matched
; Input: length of prime in mm of filament -> recalculate the length to extrusion length
var PRIME_LENGTH = 20 						; [mm] Filament length
var primeExtrusionLength = (var.FILAMENT_SECTION * var.PRIME_LENGTH) / (var.LINE_HEIGHT * var.LINE_WIDTH)

while(var.primeExtrusionLength > 0)
	G1 X{move.axes[0].userPosition + var.SIDE_LENGTH} E{var.SIDE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
	G1 Y{move.axes[1].userPosition + var.LINE_WIDTH} E{var.LINE_WIDTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
	G1 X{move.axes[0].userPosition - var.SIDE_LENGTH} E{var.SIDE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
	G1 Y{move.axes[1].userPosition + var.LINE_WIDTH} E{var.LINE_WIDTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
	set var.primeExtrusionLength = var.primeExtrusionLength - 2 * var.SIDE_LENGTH - 2 * var.LINE_WIDTH

M400
; Print up to the start position of the calibration line
G1 Y{move.axes[1].userPosition + var.SIDE_LENGTH} E{var.SIDE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}

; Print calibration line base -------------------------------------------------
M118 S{"[XYCAL] Print the calibration base"}
G1 X{move.axes[0].userPosition + var.SIDE_LENGTH} E{var.SIDE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
G1 Y{move.axes[1].userPosition - var.SIDE_LENGTH} E{var.SIDE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
G1 X{move.axes[0].userPosition - var.LINE_WIDTH} E{var.LINE_WIDTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
G1 Y{move.axes[1].userPosition + var.SIDE_LENGTH - var.LINE_WIDTH} E{(var.SIDE_LENGTH - var.LINE_WIDTH) * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
G1 X{move.axes[0].userPosition - var.SIDE_LENGTH + var.LINE_WIDTH} E{(var.SIDE_LENGTH - var.LINE_WIDTH) * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}
; remove Z backlash
G1 Y{move.axes[1].userPosition + (var.LINE_WIDTH / 2)} Z{move.axes[2].userPosition + var.LINE_HEIGHT*3} F{var.SPEED_PRINT}
M400
G1 Z{move.axes[2].userPosition - var.LINE_HEIGHT*2} F{var.SPEED_PRINT}

; Print Y calibration line ----------------------------------------------------
;Safe position of Y calibration line
M118 S{"[XYCAL] Y Line Start: "^move.axes[1].userPosition^" mm"}
var scan = 0
while(#var.PARAMETER_PATH > var.scan)
	echo >>{var.PARAMETER_PATH[var.scan]} {"yCommandPosition: "^move.axes[1].userPosition}
	set var.scan = var.scan + 1

var Y_LINE_START = {move.axes[0].userPosition + var.SIDE_LENGTH/2, move.axes[1].userPosition}
G1 X{move.axes[0].userPosition + var.SIDE_LENGTH - (var.LINE_WIDTH / 2)} E{(var.SIDE_LENGTH - (var.LINE_WIDTH / 2)) * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}

; Print X calibration line ----------------------------------------------------
;Safe position of Y calibration line
M118 S{"[XYCAL] X Line Start: "^move.axes[0].userPosition^" mm"}
set var.scan = 0
while(#var.PARAMETER_PATH > var.scan)
	echo >>{var.PARAMETER_PATH[var.scan]} {"xCommandPosition: "^move.axes[0].userPosition}
	set var.scan = var.scan + 1
var X_LINE_START = {move.axes[0].userPosition, move.axes[1].userPosition - var.SIDE_LENGTH/2}
var X_LINE_LENGTH = var.SIDE_LENGTH + (var.LINE_WIDTH / 2) + var.X_EXTRA_LENGTH
G1 Y{move.axes[1].userPosition - var.X_LINE_LENGTH} E{var.X_LINE_LENGTH * var.EXTRUSION_FACTOR} F{var.SPEED_PRINT}

;Safe measurement starting position-------------------------------------------
M98 P"/macros/variable/save_number.g" N{"calibration_line"} V{{var.X_LINE_START, var.Y_LINE_START}}

; -----------------------------------------------------------------------------
M118 S{"[print_line.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit