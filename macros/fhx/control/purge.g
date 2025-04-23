; Input Parameters:
;	- T: Tool 0 or 1 to configure
;  - S: Roll 0 or 1 
;        Roll 0: param.S = 0
;        Roll 1: param.S = 1
; Example:
;	M98 P"/macros/fhx/control/purge.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/purge.g"
M118 S{"[PURGE] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/enable_cold_extrusion.g"} F{var.CURRENT_FILE} E71057
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71058
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71059
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71060
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71061
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71062
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71063
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71064
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71065
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71066
M98 P"/macros/assert/abort_if.g" R{(param.S>2||param.S<0||param.S=1)}  Y{"Unexpected sensor value"} 		F{var.CURRENT_FILE} E71067
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required FHX_SENSOR_IDS"} 	F{var.CURRENT_FILE} E71068
M98 P"/macros/assert/abort_if.g" R{(sensors.gpIn[global.FHX_SENSOR_ID[param.T][param.S]].value == 1)}  Y{"preload first"} 		F{var.CURRENT_FILE} E71069

; Define variables-----------------------------------------------------------------------
var EXTRUSION_LENGTH        = 4500      ; [mm]
var EXTRUSION_SPEED         = 3000      ; [mm/min] (50 mm/s)
var RETRACTION_LENGTH       = - 4800    ; [mm]
var RETRACTION_LENGTH_LOOP  = - 10      ; [mm]
var loopCounterOuter    = 0 

; enable cold extrusion
M98 P"/macros/extruder/enable_cold_extrusion.g"
M598

; start purge----------------------------------------------------------------------------
set global.fhxMotorsRunning = 2 ; set motor state

if (param.S = 0)
    M567 P{param.T} E0:1:0 ; left roll
    M400
    ;M98 P"/macros/assert/abort_if.g" R{(sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0)} Y{"purging might jam merger"}  F{var.CURRENT_FILE} E71070
else
    M567 P{param.T} E0:0:1 ; right roll
    M400
    ;M98 P"/macros/assert/abort_if.g" R{(sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0)} Y{"purging might jam merger"}  F{var.CURRENT_FILE} E71071

M83     ; extruder in relative      
G92 E0      ; reset extruder

; Extruding
G1 E{var.EXTRUSION_LENGTH} F{var.EXTRUSION_SPEED}
M400
; Retracting
G1 E{var.RETRACTION_LENGTH} F{var.EXTRUSION_SPEED}
M400

G92 E0      ; reset
M82     ; extruder in absolute

M302 P0 ; disable cold extrusion

set global.fhxPreload[param.T][param.S] = false

set global.fhxMotorsRunning = null ; set motor state

if (!exists(global.fhxCheck))
    global fhxCheck = false
else 
    set global.fhxCheck = false

M98 P"/macros/fhx/control/mixratio.g" T{param.T}
; --------------------------------------------------------------------------------------
M118 S{"[PURGE] Done " ^var.CURRENT_FILE}
M99 ; proper exit