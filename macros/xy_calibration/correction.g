if !inputs[state.thisInput].active
	M99
; Description:  
;	Apply the calculated distance correction values  
; Input parameters: 
;	- F: Folder name
;	- T: Extruder name used during calibration
;	- A: Amount of scans
; Example:
; 	M98 P"/macros/xy_calibration/correction.g" F{+var.startTime} T0
; TODO:
;	- The Board ID should be saved in the variable
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/correction.g"
M118 S{"[correction.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/load.g"} 							F{var.CURRENT_FILE} E69000
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.F)} 		Y{"Missing required input parameter F"} F{var.CURRENT_FILE} E69010
M98 P"/macros/assert/abort_if_null.g" R{param.F}  	 		Y{"Input parameter F is null"} 		 	F{var.CURRENT_FILE} E69011
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)} 		Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E69012
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	 		Y{"Input parameter T is null"} 		 	F{var.CURRENT_FILE} E69013	
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)} Y{"Unexpected tool value"} 				F{var.CURRENT_FILE} E69014
M98 P"/macros/assert/abort_if.g" R{!exists(param.A)} 		Y{"Missing required input parameter A"} 	F{var.CURRENT_FILE} E69015
M98 P"/macros/assert/abort_if.g" R{#param.A == 0}  	 		Y{"Input parameter A is null"} 		 		F{var.CURRENT_FILE} E69016

; Definitions -----------------------------------------------------------------
var calibrationPath = ""
; (!) This path is shared between others xy_calibration g-codes
if(boards[0].shortName != "EMU_CB-MA")
	set var.calibrationPath = {"/sys/xy_calibration/results/"^param.F^"_"} ; Path where the files are saved
else
	set var.calibrationPath = {"/sys/modules/xy_calibration/emulation_files/T"^param.T^"_"} ; Path where the files are saved

var AMOUNT_SCANS = param.A
var correctionDistance = param.A

var xCalibrationPath = var.AMOUNT_SCANS
var yCalibrationPath = var.AMOUNT_SCANS

var scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	set var.xCalibrationPath[var.scan] = {var.calibrationPath ^ var.scan ^ "/x.csv"}			 ; X Calibration data 
	set var.yCalibrationPath[var.scan] = {var.calibrationPath ^ var.scan ^ "/y.csv"}			 ; Y Calibration data
	set var.scan = var.scan + 1

var CALIBRATION_VARIABLE = {"correction_t"^param.T}					 ; Calibration variable stored in the sd-card
var MAXIMUM_CORRECTION = 5											 ; [mm] Maximum allowable correction value in x and y direction
var MAXIMUM_DEVIATION = 1											 ; [mm] Maximum allowable deviation between the scan and the mean of all scans

; Checking for required calibration files  ------------------------------------
set var.scan = 0
M400
M598
while(#var.AMOUNT_SCANS > var.scan)
	M98 P"/macros/assert/abort_if_file_missing.g" R{var.xCalibrationPath[var.scan]} 					F{var.CURRENT_FILE}  E69020
	M98 P"/macros/assert/abort_if_file_missing.g" R{var.yCalibrationPath[var.scan]} 					F{var.CURRENT_FILE}  E69021
	set var.scan = var.scan + 1
M400

; Call Python to calculate the correction distances---------------------------

; return_messages = {
;         "valid": [0, ""],
;         "NoLine": [-400, "No line was detected"],
;         "MultiPeak": [-401, "More then one peak detected"],
;         "PosDev": [-402, "Position deviation is to large"],
;         "SmallPeak": [-403, "Detected peak is to small"],
;         "NoPos": [-404, "No valid position found"],
;     }


set var.scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	M118 S{"[correction.g] Calling python to execute XY calibration for measurement: "^var.calibrationPath^var.scan^"/"}
	M98 P"/macros/python/call_function.g" N"XY_CALIB" F{var.calibrationPath^var.scan^"/"}
	M98 P"/macros/assert/abort_if.g" R{!exists(global.pythonResult)} Y{"XY Calibration failed: Please clean the printbed and retry"}  F{var.CURRENT_FILE} E69022
	M98 P"/macros/assert/abort_if_null.g" R{global.pythonResult}  	 Y{"XY Calibration failed: Please clean the printbed and retry"} 				F{var.CURRENT_FILE} E69023

	; Load the calculated correction values 
	M98 P"/macros/variable/load.g" N{var.CALIBRATION_VARIABLE}
	M400
	M98 P"/macros/assert/abort_if.g" R{!exists(global.savedValue)} Y{"XY Calibration failed: Please clean the printbed and retry"}  					 F{var.CURRENT_FILE} E69024
	M98 P"/macros/assert/abort_if_null.g" R{global.savedValue}     Y{"XY Calibration failed: Please clean the printbed and retry"} F{var.CURRENT_FILE} E69025
	M118 S{"[correction.g] Python returned correction: " ^ global.savedValue}

	var savedValueString = ""^global.savedValue
	var hmi_error = false
	if var.savedValueString == "-400"
		set var.hmi_error = true
	elif var.savedValueString == "-401"
		set var.hmi_error = true
	elif var.savedValueString == "-402"
		set var.hmi_error = true
	elif var.savedValueString == "-403"
		set var.hmi_error = true
	elif var.savedValueString == "-404"
		set var.hmi_error = true
	elif var.savedValueString == "0"
		set var.hmi_error = true

	if var.hmi_error
		M98 P"/macros/assert/abort.g" Y{"XY Calibration failed: Please Clean the printbed and retry"} F{var.CURRENT_FILE} E69031

	M98 P"/macros/assert/abort_if.g" R{#global.savedValue != 3} Y{"XY Calibration failed. Please clean the printbed and retry"}  					 F{var.CURRENT_FILE} E69030
	set var.correctionDistance[var.scan] = global.savedValue

	M118 S{"------------------------------------------------------------------------------"}
	M118 S{"[correction.g] T"^param.T^" correction distance: "^{var.correctionDistance[var.scan][0]}^", "^{var.correctionDistance[var.scan][1]}^", "^{var.correctionDistance[var.scan][2]}}
	M118 S{"------------------------------------------------------------------------------"}
	if(#(var.correctionDistance[var.scan]) < 2)
		M98 P"/macros/xy_calibration/abort_from_python.g" C{var.correctionDistance[var.scan][0]}

	; Delete the file "CALIBRATION_VARIABLE". This makes sure, that the next calibration needs to write a valid calibration
	M30 {"/sys/variables/"^var.CALIBRATION_VARIABLE^".g"}
	set var.scan = var.scan + 1
M400
; Check deviation of correction distances and calculate average ---------------
var xMeanCorrectionDistance = 0
var yMeanCorrectionDistance = 0
var zMeanCorrectionDistance = 0
set var.scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	set var.xMeanCorrectionDistance = var.xMeanCorrectionDistance + var.correctionDistance[var.scan][0]
	set var.yMeanCorrectionDistance = var.yMeanCorrectionDistance + var.correctionDistance[var.scan][1]
	set var.zMeanCorrectionDistance = var.zMeanCorrectionDistance + var.correctionDistance[var.scan][2]
	set var.scan = var.scan + 1  
set var.xMeanCorrectionDistance = {var.xMeanCorrectionDistance / (#var.AMOUNT_SCANS)}
set var.yMeanCorrectionDistance = {var.yMeanCorrectionDistance / (#var.AMOUNT_SCANS)}
set var.zMeanCorrectionDistance = {var.zMeanCorrectionDistance / (#var.AMOUNT_SCANS)}

M118 S{"[correction.g] T"^param.T^" Mean Correction Value: "^{var.xMeanCorrectionDistance}^", "^{var.yMeanCorrectionDistance}^", "^{var.zMeanCorrectionDistance}}

;Check deviation of the line from the mean. If to large abort.
var xDeviation = 0
var yDeviation = 0
set var.scan = 0
while(#var.AMOUNT_SCANS > var.scan)
	set var.xDeviation = abs(var.xMeanCorrectionDistance - var.correctionDistance[var.scan][0])
	set var.yDeviation = abs(var.yMeanCorrectionDistance - var.correctionDistance[var.scan][1])
	M98 P"/macros/assert/abort_if.g" R{var.xDeviation > var.MAXIMUM_DEVIATION} Y{"XY Calibration failed: Deviation between scans in X direction exceeds maximum"} F{var.CURRENT_FILE} E69026
	M98 P"/macros/assert/abort_if.g" R{var.yDeviation > var.MAXIMUM_DEVIATION} Y{"XY Calibration failed: Deviation between scans in Y direction exceeds maximum"} F{var.CURRENT_FILE} E69027
	set var.scan = var.scan + 1

; Changing the offset ---------------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{var.xMeanCorrectionDistance > var.MAXIMUM_CORRECTION} Y{"XY Calibration failed: Correction in X direction exceeds maximum"} F{var.CURRENT_FILE} E69028
M98 P"/macros/assert/abort_if.g" R{var.yMeanCorrectionDistance > var.MAXIMUM_CORRECTION} Y{"XY Calibration failed: Correction in Y direction exceeds maximum"} F{var.CURRENT_FILE} E69029
; new offsets need to be negated since the HMI only provides the from command position to actual position
M98 P"/macros/xy_calibration/set_offset_correction.g" T{param.T} X{-1 * var.xMeanCorrectionDistance} Y{-1 * var.yMeanCorrectionDistance} Z{0} ; not reliable yet
; -----------------------------------------------------------------------------
M118 S{"[correction.g] Done "^var.CURRENT_FILE} 
M99