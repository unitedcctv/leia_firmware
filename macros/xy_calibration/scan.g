if !inputs[state.thisInput].active
	M99
; Description:  
;	Scan the XY calibration pattern. 
; Input parameters: 
;	- H: Line height
;	- F: Folder name
;   - A: Amount of scans. This is an array of empty strings!
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/scan.g"
M118 S{"[scan.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/load.g"} 	E69100
; Checking input parameters
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  Y{"Missing modules PROBES"}					F{var.CURRENT_FILE} E69110
M98 P"/macros/assert/abort_if.g" R{!exists(global.PROBE_OFFSET_Z)} Y{"Missing global variable PROBE_OFFSET_Z"} 	F{var.CURRENT_FILE}	E69111
M98 P"/macros/assert/abort_if.g" R{!exists(param.H)} 				Y{"Missing required input parameter H"} 	F{var.CURRENT_FILE} E69112
M98 P"/macros/assert/abort_if_null.g" R{param.H}  	 				Y{"Input parameter H is null"} 		 		F{var.CURRENT_FILE} E69113
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)} 				Y{"Missing required input parameter F"} 	F{var.CURRENT_FILE} E69114
M98 P"/macros/assert/abort_if_null.g" R{param.F}  	 				Y{"Input parameter F is null"} 		 		F{var.CURRENT_FILE} E69115
M98 P"/macros/assert/abort_if.g" R{!exists(param.A)} 				Y{"Missing required input parameter A"} 	F{var.CURRENT_FILE} E69116
M98 P"/macros/assert/abort_if.g" R{#param.A == 0}  	 				Y{"Input parameter A is null"} 		 		F{var.CURRENT_FILE} E69117
; Check machine conditions
var IS_NOT_HOMED = (!move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed )
M98 P"/macros/assert/abort_if.g" R{var.IS_NOT_HOMED}  Y{"Home required before running bed mesh"}  F{var.CURRENT_FILE} E69120

; Checking input parameters ---------------------------------------------------
var LINE_HEIGHT = param.H
;TODO: Rename AMOUNT_SCANS since it is array of strings!
var AMOUNT_SCANS = param.A 

; Definitions -----------------------------------------------------------------
var SPEED_FAST_MOVE 		= 12000							  	; [mm/min] Fast move speed
var SPEED_MEASUREMENT 		= 300							   	; [mm/min] Measurement move speed
var MEASURE_LENGTH 			= 18								; [mm] Measurement distance
var MEASURE_HEIGHT 			= global.PROBE_OFFSET_Z				; [mm] Z height for measurement
var LIFTING_Z 				= 20								; [mm] To lift Z
var TRAVEL_HEIGHT_Z			= 3									; [mm] Travel position of the Z axis 
var SCAN_DISTANCE			= 4									; [mm] Spread range for the scan lines

var SAMPLE_FREQUENCY		= 250								; [1/s] Sample frequency of the ball sensor

var SAMPLES_TO_DISCARD		= 128							; [1] Amount of samples to discard, duet to stream being delayed in FW
															; we discard samples by moving ahead of the start point of the scan by the distance equivalent to the sample count
															; effectively moving all measured features ahead by the discarded sample count
var COOL_DOWN_TIME			= 20							; [s] Cooldown time, to make sure the filament is hard enough to scan
var linePosition				= {{0,0},{0,0}}

var MAGIC_HEIGHT_SCALING = 1/3

M98 P"/macros/variable/load.g" N{"calibration_line"}		; [mm] Center position of the X and Y calibration line
set var.linePosition 			= global.savedValue


; Calculate amount of samples needed to measure whole distance-----------------
var AMOUNT_SAMPLES			= ceil((var.MEASURE_LENGTH / (var.SPEED_MEASUREMENT/60)) * var.SAMPLE_FREQUENCY)
; How much does the correction need to be corrected, based on the discarded samples
var DISCARD_LENGTH   = var.SAMPLES_TO_DISCARD / var.SAMPLE_FREQUENCY * var.SPEED_MEASUREMENT / 60
var DISCARD_TIME_S = var.SAMPLES_TO_DISCARD / var.SAMPLE_FREQUENCY

M118 S{"[XYCAL] Discarding "^var.SAMPLES_TO_DISCARD^" samples: "^var.DISCARD_LENGTH^" mm"}

var SCAN_X_START			= {var.linePosition[0][0] - (var.MEASURE_LENGTH / 2), var.linePosition[0][1] + (var.SCAN_DISTANCE / 2)}		; [mm] Starting position of X line measurement
var SCAN_Y_START			= {var.linePosition[1][0] + (var.SCAN_DISTANCE / 2), var.linePosition[1][1] - (var.MEASURE_LENGTH / 2)}		; [mm] Starting position of Y line measurement

;Configure filenaming ---------------------------------------------------------
; (!) This path is shared between others xy_calibration g-codes
var paraPath = var.AMOUNT_SCANS
var xCalibrationPath = var.AMOUNT_SCANS
var yCalibrationPath = var.AMOUNT_SCANS

var CALIBRATION_PATH = {"/sys/xy_calibration/results/"^param.F^"_"} ; Path where the files are saved
var scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	set var.paraPath[var.scan] = {var.CALIBRATION_PATH ^ var.scan ^ "/parameters.csv"}		; Parameters data file
	set var.xCalibrationPath[var.scan] = {var.CALIBRATION_PATH ^ var.scan ^ "/x.csv"}			 ; X Calibration data
	set var.yCalibrationPath[var.scan] = {var.CALIBRATION_PATH ^ var.scan ^ "/y.csv"}			 ; Y1 Calibration data
	set var.scan = var.scan + 1

; Write into result file (needs to be created already in start.g!) ------------
set var.scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	echo >>{var.paraPath[var.scan]} {"measurementSpeed: "^{var.SPEED_MEASUREMENT}}
	echo >>{var.paraPath[var.scan]} {"measurementDistance: "^var.MEASURE_LENGTH}
	echo >>{var.paraPath[var.scan]} {"printHeight: "^var.LINE_HEIGHT * 2 * var.MAGIC_HEIGHT_SCALING} ; we are stacking 2 lines on top of each other
	echo >>{var.paraPath[var.scan]} {"xInitialPosition: "^{var.SCAN_X_START[0]}}
	echo >>{var.paraPath[var.scan]} {"yInitialPosition: "^{var.SCAN_Y_START[1]}}
	M118 S{"[XYCAL] New file available with parameters: "^var.paraPath[var.scan]}
	set var.scan = var.scan + 1

M400

; Deselecting the tool --------------------------------------------------------
if(state.currentTool >= 0)
	T{-1}

M400
; Moving to Y calibration line position ---------------------------------------
G1 X{var.SCAN_Y_START[0]} Y{var.SCAN_Y_START[1]} F{var.SPEED_FAST_MOVE}
G1 Z{var.MEASURE_HEIGHT} F{var.SPEED_FAST_MOVE}
M118 S{"[XYCAL] Start scanning Y line from X"^var.SCAN_Y_START[0]^" Y"^var.SCAN_Y_START[1]^" Z"^var.MEASURE_HEIGHT}

; Measure calibration line in Y direction
; For each line we scan two times in same direction to make sure the filament did not move or deform
; Wait to give filament time to cool down a little bit, without hot extruders in the near distance
G4 S{var.COOL_DOWN_TIME}
M400
G91 ; relative

M400
set var.scan = 0 
while(#var.AMOUNT_SCANS > var.scan)
	G1 Y{var.DISCARD_LENGTH} F{var.SPEED_MEASUREMENT}
	M400
	if(boards[0].shortName != "EMU_CB-MA")
		M956 P70.1 S{var.AMOUNT_SAMPLES} Z A1 F{var.yCalibrationPath[var.scan]} ; Start recording
	M400
	G1 Y{var.MEASURE_LENGTH-var.DISCARD_LENGTH} F{var.SPEED_MEASUREMENT}
	M118 S{"[XYCAL] Done scanning Y line in X"^var.SCAN_Y_START[0]^" Y"^(var.SCAN_Y_START[1] + var.MEASURE_LENGTH)^" Z"^var.MEASURE_HEIGHT}
	M118 S{"[XYCAL] New file available with Y line samples: "^var.yCalibrationPath[var.scan]}
	; Move little bit in x-direction and go back to measurement distance in y to scan in same direction
	if((#var.AMOUNT_SCANS - 1) > var.scan )
		G1 X{-var.SCAN_DISTANCE / (#var.AMOUNT_SCANS - 1)} Z{var.TRAVEL_HEIGHT_Z} F{var.SPEED_FAST_MOVE}
		G1 Y{-var.MEASURE_LENGTH}
		G1 Z{-var.TRAVEL_HEIGHT_Z}
	M400
	set var.scan = var.scan + 1

M400
G90 ; absolute

G1 Z3 F{var.SPEED_FAST_MOVE}

; Moving to X calibration line position ---------------------------------------
G1 X{var.SCAN_X_START[0]} Y{var.SCAN_X_START[1]} F{var.SPEED_FAST_MOVE}
G1 Z{var.MEASURE_HEIGHT} F{var.SPEED_FAST_MOVE}
M118 S{"[XYCAL] Start scanning X line from X"^var.SCAN_X_START[0]^" Y"^var.SCAN_X_START[1]^" Z"^var.MEASURE_HEIGHT}

G91 ; relative
; Measure calibration line in X direction
set var.scan = 0 
while(#var.AMOUNT_SCANS > var.scan)
	G1 X{var.DISCARD_LENGTH} F{var.SPEED_MEASUREMENT}
	M400
	if(boards[0].shortName != "EMU_CB-MA")
		M956 P70.1 S{var.AMOUNT_SAMPLES} Z A1 F{var.xCalibrationPath[var.scan]} ; Start recording
	M400
	G1 X{var.MEASURE_LENGTH-var.DISCARD_LENGTH} F{var.SPEED_MEASUREMENT}
	M118 S{"[XYCAL] Done scanning X line in X"^(var.SCAN_X_START[0]+var.MEASURE_LENGTH)^" Y"^var.SCAN_X_START[1]^" Z"^var.MEASURE_HEIGHT}
	M118 S{"[XYCAL] New file available with X line samples: "^var.xCalibrationPath[var.scan]}
	; Move little bit in y and go back to measurement distance in x to scan in same direction
	if((#var.AMOUNT_SCANS - 1) > var.scan )
		G1 Y{-var.SCAN_DISTANCE / (#var.AMOUNT_SCANS - 1)} Z{var.TRAVEL_HEIGHT_Z} F{var.SPEED_FAST_MOVE}
		G1 X{-var.MEASURE_LENGTH}
		G1 Z{-var.TRAVEL_HEIGHT_Z}
	M400
	set var.scan = var.scan + 1

M400

G90 ; absolute
G1 Z{var.TRAVEL_HEIGHT_Z} F{var.SPEED_FAST_MOVE}

; -----------------------------------------------------------------------------
M118 S{"[scan.g] Done "^var.CURRENT_FILE}
M99