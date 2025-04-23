; Description: 	
;	This will set mix ratio (control motor movement for box plus extruder) for general usage of the printer
; Input Parameters:
;	- T: Tool 0 or 1 to configure
; Example:
;	M98 P"/macros/fhx/control/mixratio.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/mixratio.g"
M118 S{"[MR] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/report/event.g"} F{var.CURRENT_FILE} E71052
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71053
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71054
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71055
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors of the infinity box"} 	F{var.CURRENT_FILE} E71056

; creating variables------------------------------------------------------
var box = ""
var roll0 = ""
var roll1 = ""
var LEFT_TOP_SENS_VAL = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][0]].value)
var LEFT_BOTM_SENS_VAL = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value)
var RIGHT_TOP_SENS_VAL = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][2]].value)
var RIGHT_BOTM_SENS_VAL = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value)
; Sensor values and machine status
var LEFT_SPOOL_EMPTY = (var.LEFT_TOP_SENS_VAL == 1) && (var.LEFT_BOTM_SENS_VAL == 1)
var RIGHT_SPOOL_EMPTY = (var.RIGHT_TOP_SENS_VAL == 1) && (var.RIGHT_BOTM_SENS_VAL == 1)
var LEFT_SPOOL_PRELOADED = (var.LEFT_TOP_SENS_VAL == 0) && (var.LEFT_BOTM_SENS_VAL == 1)
var RIGHT_SPOOL_PRELOADED = (var.RIGHT_TOP_SENS_VAL == 0) && (var.RIGHT_BOTM_SENS_VAL == 1)
var BOTH_SPOOLS_PRELOADED = (var.LEFT_TOP_SENS_VAL == 0) && (var.RIGHT_TOP_SENS_VAL == 0)
var BOTH_SPOOLS_EMPTY = var.LEFT_SPOOL_EMPTY && var.RIGHT_SPOOL_EMPTY
var LEFT_SPOOL_LOADED = (var.LEFT_TOP_SENS_VAL == 0) && (var.LEFT_BOTM_SENS_VAL == 0)
var RIGHT_SPOOL_LOADED = (var.RIGHT_TOP_SENS_VAL == 0) && (var.RIGHT_BOTM_SENS_VAL == 0)
var LEFT_SPOOL_OOF = (var.LEFT_TOP_SENS_VAL == 1) && (var.LEFT_BOTM_SENS_VAL == 0)
var RIGHT_SPOOL_OOF = (var.RIGHT_TOP_SENS_VAL == 1) && (var.RIGHT_BOTM_SENS_VAL == 0)
; variable for debugging the rolls
if (param.T == 0)
	set var.box = "T0 Box"
	set var.roll0 = "left spool"
	set var.roll1 = "right spool"
else
	set var.box = "T1 Box"
	set var.roll0 = "left spool"
	set var.roll1 = "right spool"

; setting mr-----------------------------------------------------------------
; preloaded conditions

if (var.LEFT_SPOOL_LOADED)
	M567 P{param.T} E{1,1,0} ; motor 0 loaded (left motor)
	M118 S{"LEFT_SPOOL_LOADED: Set MR for filament "^var.box^" "^var.roll0}
elif (var.RIGHT_SPOOL_LOADED)
	M567 P{param.T} E{1,0,1} ; motor 1 loaded (right motor)
	M118 S{"RIGHT_SPOOL_LOADED: Set MR for filament "^var.box^" "^var.roll1}
elif (var.LEFT_SPOOL_OOF)
	M567 P{param.T} E{1,1,0} ; motor 0 loaded (left motor)
	M118 S{"LEFT_SPOOL_OOF: Set MR for filament "^var.box^" "^var.roll0}
elif (var.RIGHT_SPOOL_OOF)
	M567 P{param.T} E{1,0,1} ; motor 1 loaded (right motor)
	M118 S{"RIGHT_SPOOL_OOF: Set MR for filament "^var.box^" "^var.roll1}
elif (var.LEFT_SPOOL_PRELOADED)
	M567 P{param.T} E{1,1,0} ; motor 0 loaded (left motor)
	M118 S{"LEFT_SPOOL_PRELOADED: Set MR for filament "^var.box^" "^var.roll0}
elif (var.RIGHT_SPOOL_PRELOADED)
	M567 P{param.T} E{1,0,1} ; motor 1 loaded (right motor)
	M118 S{"RIGHT_SPOOL_PRELOADED: Set MR for filament "^var.box^" "^var.roll1}
else
	M567 P{param.T} E{1,0,0} ; set to extruder both rolls missing
	M118 S{var.box^" is empty"}
M400

if((var.LEFT_SPOOL_OOF && var.RIGHT_SPOOL_OOF) || (var.LEFT_SPOOL_LOADED && var.RIGHT_SPOOL_LOADED))
	M567 P{param.T} E{0,0,0} ; both bottom sensors detect filament
	if(state.status == "processing")
		M98 P"/macros/report/event.g" Y{"Pausing due to filament jam in %s, wait for further instructions."} A{var.box,} F{var.CURRENT_FILE} V72103
		M25	; Pausing, pause calls safety
	else
		M98 P"/macros/report/event.g" Y{"Possible jam in %s. Please check the Filament paths and unload."} A{var.box,} F{var.CURRENT_FILE} V72109
M400
; -----------------------------------------------------------------------------
M118 S{"[mixratio.g] Done " ^var.CURRENT_FILE}
M99 ; Proper exit