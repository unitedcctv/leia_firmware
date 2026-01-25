if !inputs[state.thisInput].active
	M99
; Input parameters: 
;	- T: Temperture of used tools:
;			Formate is [t0_temp, t0_standby, t1_temp, t1_standby]. If extuder not used
;			set temperuters to null.
; Description: 	
;	We will start the XY calibration process
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/xy_calibration/xy_calibration.g"
M118 S{"[xy_calibration.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Version of XY-Calibration. Needs to be set by hand, since metafunction are in different repository
var XY_CALIBRATION_VERSION = "1.0.0"
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/xy_calibration/start.g"} 		F{var.CURRENT_FILE} E69200
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/boards/get_index_in_om.g"} 	F{var.CURRENT_FILE} E69201
; Checking input parameters
M598
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_XY_CALIBRATION)}  Y{"Missing modules XY_CALIBRATION"} F{var.CURRENT_FILE} E69210
; Checking HMI metafunction version ---------------------------------------
if(!exists(global.META_FUNCTION_VERSION))
	global META_FUNCTION_VERSION = ""
M98 P"/macros/python/call_function.g" N"META_VERSION"
M598
M98 P"/macros/assert/abort_if.g" R{!exists(global.pythonResult)} Y{"Missing required global pythonResult"}  F{var.CURRENT_FILE} E69211
M98 P"/macros/assert/abort_if_null.g" R{global.pythonResult}  	 Y{"No answer from Python"} 				F{var.CURRENT_FILE} E69212
M98 P"/macros/assert/abort_if.g" R{global.META_FUNCTION_VERSION != var.XY_CALIBRATION_VERSION} Y{"HMI MetaFunction Version does not match SD-Card"}  F{var.CURRENT_FILE} E69213

M98 P"/macros/assert/abort_if.g" 		R{!exists(param.T)} 	Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E69214
M98 P"/macros/assert/abort_if.g" 		R{#param.T != 4} 	Y{"Wrong number of inputs provided for parameter T"} 	F{var.CURRENT_FILE} E69215
; Definitions -----------------------------------------------------------------
; Set temperatures for T0 and T1, if no standby temp is set, use the same as the print temp
var TEMPERATURE_T0 = {param.T[0], (param.T[1] != null ? param.T[1] : param.T[0])}
var TEMPERATURE_T1 = {param.T[2], (param.T[3] != null ? param.T[3] : param.T[2])}

; check which extruders we calibrate for
var inUseT0 = {var.TEMPERATURE_T0[0] != null} 
var inUseT1 = {var.TEMPERATURE_T1[0] != null}

; Abort if we try to calibrate nonexisting extruders
M98 P"/macros/assert/abort_if.g" R{var.inUseT0 && !exists(global.MODULE_EXTRUDER_0)} Y{"Trying to calibrate nonexisting extruder T0"} F{var.CURRENT_FILE} E69216
M98 P"/macros/assert/abort_if.g" R{var.inUseT1 && !exists(global.MODULE_EXTRUDER_1)} Y{"Trying to calibrate nonexisting extruder T1"} F{var.CURRENT_FILE} E69217

var OFFSET_X_DEFAULT 	= {-8.35,-8.35}		; [mm] Default offset in X for T0 and T1
var OFFSET_Y_DEFAULT 	= {-48.9, 47.1}		; [mm] Default offset in Y for T0 and T1
; Set the default tool offsets before xy calib
if var.inUseT0
	M98 P"/sys/modules/extruders/basic_set_offset.g" T0 X{var.OFFSET_X_DEFAULT[0]} Y{var.OFFSET_Y_DEFAULT[0]}
M400
if var.inUseT1
	M98 P"/sys/modules/extruders/basic_set_offset.g" T1 X{var.OFFSET_X_DEFAULT[1]} Y{var.OFFSET_Y_DEFAULT[1]}
M400

var LINE_LENGTH = 20 													; length of the calibration line
var patternPositionT0 = {move.axes[0].min, 200}							; Position of the T0 pattern
var patternPositionT1 = {move.axes[0].min + var.LINE_LENGTH + 5, 200}	; Position of the T1 pattern

; set flag that xyCalibration is running so that the emergency trigger is disabled!
if(!exists(global.xyCalibrationRunning))
	global xyCalibrationRunning = true
else
	set global.xyCalibrationRunning = true

; Save current selected extruder
var TOOL_BEFORE_CALIB = state.currentTool

; Start xy-calibration T0 -----------------------------------------------------
M83 ; Absolute extrusion
if(var.inUseT0)
	M118 S{"[XYCAL] Starting XY-calibration for T0 at " ^ var.TEMPERATURE_T0[0] ^ "°C"}

	M568 P0 A2 R{var.TEMPERATURE_T0[0]} S{var.TEMPERATURE_T0[0]}; set T0 to calibration temperature
	set global.exTempLastSetTimes[0] = state.upTime
	if(var.inUseT1) ; if we also calibrate T1, heat it to its standby temperature, but do not wait for it
		M568 P1 A2 R{var.TEMPERATURE_T1[1]} S{var.TEMPERATURE_T1[1]}
		set global.exTempLastSetTimes[1] = state.upTime

	M116 P0 S5; wait for T0 to reach temperature
	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T0 F1
	M400

	M98 P"/macros/xy_calibration/start.g" T0 X{var.patternPositionT0} L{var.LINE_LENGTH}
	M400
	;Validation pattern -----------------------------------------------------------	
	M118 S{"[XYCAL] Second run T0"}
	set var.patternPositionT0 = {var.patternPositionT0[0], var.patternPositionT0[1] + 80}

	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T0 F0
	M400
	M98 P"/macros/xy_calibration/start.g" T0 X{var.patternPositionT0} L{var.LINE_LENGTH}

M400
; Start xy-calibration T1 -----------------------------------------------------	
if(var.inUseT1)
	M118 S{"[XYCAL] Starting XY-calibration for T1 at " ^ var.TEMPERATURE_T1[0] ^ "°C"}

	M568 P1 A2 R{var.TEMPERATURE_T1[0]} S{var.TEMPERATURE_T1[0]}; set T1 to calibration temperature
	if(var.inUseT0) ; if we also calibrate T0, heat it to its standby temperature, but do not wait for it
		M568 P0 A2 R{var.TEMPERATURE_T0[1]} S{var.TEMPERATURE_T0[1]}

	M116 P1 S5; wait for T1 to reach temperature
	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T1 F1
	M400

	M98 P"/macros/xy_calibration/start.g" T1 X{var.patternPositionT1} L{var.LINE_LENGTH}
	M400

	;Validation pattern ----------------------------------------------------------
	M118 S{"[XYCAL] Second run T1"}
	set var.patternPositionT1 = {var.patternPositionT1[0], var.patternPositionT1[1] + 80}

	if(global.wiperPresent)
		M98 P"/macros/nozzle_cleaner/wipe.g" T1 F0
	M400
	M98 P"/macros/xy_calibration/start.g" T1 X{var.patternPositionT1} L{var.LINE_LENGTH}

M400

; Reset temperatures to before calibration
if(var.TOOL_BEFORE_CALIB == 0)
	M568 P0 A2 R{var.TEMPERATURE_T0[0]} S{var.TEMPERATURE_T0[0]}
	if(var.inUseT1)
		M568 P1 A2 R{var.TEMPERATURE_T1[1]} S{var.TEMPERATURE_T1[1]}
else
	M568 P1 A2 R{var.TEMPERATURE_T1[0]} S{var.TEMPERATURE_T1[0]}
	if(var.inUseT0)
		M568 P0 A2 R{var.TEMPERATURE_T0[1]} S{var.TEMPERATURE_T0[1]}

; reset extruder cooldown timer
if(var.inUseT0)
	set global.exTempLastSetTimes[0] = state.upTime

if(var.inUseT1)
	set global.exTempLastSetTimes[1] = state.upTime

; Reselect the extruder active before calibration
T{var.TOOL_BEFORE_CALIB}
; Wait to be back on temperature
M116 P{var.TOOL_BEFORE_CALIB} S5
G92 E0
set global.xyCalibrationRunning = false

; -----------------------------------------------------------------------------
M118 S{"[xy_calibration.g] Done "^var.CURRENT_FILE}
M99