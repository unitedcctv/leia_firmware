if !inputs[state.thisInput].active
	M99
; Description: 	
;	We will start the XY calibration process
; Input parameters: 
;	- T: Tool
;	- X: [mm] Position of the pattern
;	- L: [mm] Line length
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/start.g"
M118 S{"[start.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" 	R{"/macros/xy_calibration/print_line.g"} 	F{var.CURRENT_FILE} E69220
M98 P"/macros/assert/abort_if_file_missing.g" 	R{"/macros/xy_calibration/scan.g"}  		F{var.CURRENT_FILE} E69221
M98 P"/macros/assert/abort_if_file_missing.g" 	R{"/macros/xy_calibration/correction.g"}  	F{var.CURRENT_FILE} E69222

; Checking input parameters
M98 P"/macros/assert/abort_if.g" 		R{!exists(global.MODULE_XY_CALIBRATION)}  	Y{"Missing modules XY_CALIBRATION"} 		F{var.CURRENT_FILE} E69230
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.T)} 						Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E69231
M98 P"/macros/assert/abort_if_null.g" 	R{param.T} 									Y{"Input parameter T is null"} 				F{var.CURRENT_FILE} E69232
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.X)} 						Y{"Missing required input parameter X"} 	F{var.CURRENT_FILE} E69233
M98 P"/macros/assert/abort_if_null.g" 	R{param.X} 									Y{"Input parameter X is null"} 				F{var.CURRENT_FILE} E69234

; Definitions -----------------------------------------------------------------
var PATTERN_POSITION = param.X					; [mm] position of lower left corner of pattern on the printbed
var LINE_LENGTH_DEFAULT = 20					; [mm] default line length
var LINE_HEIGHT	= 0.3							; [mm] Line height
; 	If you want to change the amount of scans add or remove empty strings.
; 	that is really ugly but I don't see an other way. 
var AMOUNT_SCANS = {"", ""}			; Amount of scans per line

var LINE_LENGTH = { (param.L != 0) ? param.L : var.DEFAULT_LINE_LENGTH }

; Start calibration -----------------------------------------------------------
T{param.T}
; create folders where the calibration results are stored in. Name is current time and calibration run
; we are scanning at least two times per line to make sure the line did not detache or move!
var START_TIME = state.time
var CALIBRATION_PATH = {"/sys/xy_calibration/results/"^(+var.START_TIME)^"_"} ; Path where the files are saved
var paraPath = var.AMOUNT_SCANS
var scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	set var.paraPath[var.scan] = {var.CALIBRATION_PATH^var.scan^"/parameters.csv"}		; Parameters data file
	M118 S{"[XYCAL] Calibration Parameter stored in: "^var.paraPath[var.scan]}
	echo >{var.paraPath[var.scan]} {"tool: "^{param.T}}
	set var.scan = var.scan + 1
M400

; Print the calibration pattern -----------------------------------------------
M98 P"/macros/xy_calibration/print_line.g" X{var.PATTERN_POSITION} L{var.LINE_LENGTH} H{var.LINE_HEIGHT} F{+var.START_TIME} A{var.paraPath}
M400
M98 P"/macros/printing/abort_if_forced.g" Y{"After printing calibration pattern for T"^param.T} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
; Scan the calibration pattern ------------------------------------------------
M98 P"/macros/xy_calibration/scan.g" H{var.LINE_HEIGHT} F{+var.START_TIME} A{var.AMOUNT_SCANS}
M400
M98 P"/macros/printing/abort_if_forced.g" Y{"After scanning calibration pattern for T"^param.T} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
; Calculate the correction values --------------------------------------------
M98 P"/macros/xy_calibration/correction.g" F{+var.START_TIME} T{param.T} A{var.AMOUNT_SCANS}
M400
M98 P"/macros/printing/abort_if_forced.g" Y{"After XY calibration correction for T"^param.T} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}

M118 S{"[XYCAL] Setting absolute extrusion back"}
M82 ; Absolute extrusion
G92 E0
; -----------------------------------------------------------------------------
M118 S{"[start.g] Done "^var.CURRENT_FILE}
M99