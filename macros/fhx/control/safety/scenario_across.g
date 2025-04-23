; Description: 	
;	called (by load, pause, load extruder and preload) if unwanted sensor activation is detected 
; Example:
;	M98 P"/macros/fhx/control/safety/scenario_across.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/safety/scenario_across.g"
M118 S{"[SENSOR CHECK] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files00
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/recover_tool_temp.g"} F{var.CURRENT_FILE} E71023
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71024
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71025
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71026
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71027
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71028
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71029
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxCheck)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71030

; set variables------------------------------------------
var EXTRUSION_LENGTH       = 10    ; mm
var EXTRUSION_SPEED        = 120   ; [mm/m] = 2 mm/s
var sensor                 = null
var loopCounterOuter       = 0

if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0)
	M567 P{param.T} E{1,1,0} ; motor 0 loaded (left motor)
	set var.sensor = 1
else
	M567 P{param.T} E{1,0,1} ; motor 1 (right motor) loaded 
	set var.sensor = 3

;resolving jam---------------------------------------------------------------------
M83     ; extruder in relative      
G92 E0      ; reset extruder

if ((state.status == "pausing") || (state.status == "paused"))
	M98 P"/macros/printing/recover_tool_temp.g" ; checking if the extruder is still hot
	M116
	M598 
set global.fhxMotorsRunning = 1
M118 S{"Resolving filament jam, please wait"}
while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensor]].value == 0) && (var.loopCounterOuter < 20))
	set var.loopCounterOuter = iterations
	G1 E{var.EXTRUSION_LENGTH} F{var.EXTRUSION_SPEED} ; retracting until at least one sensor is not activated
M400
if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensor]].value == 0) || (var.loopCounterOuter >= 20))
	M567 P{param.T} E{0,0,0}
	M400
	set global.fhxCheck = true     ; filament still stuck
	M98 P"/macros/report/event.g" Y{"Filament stuck, please unload preloaded roll and check the filament path to Tool %s"} A{param.T,} F{var.CURRENT_FILE} V72102
else
	M118 S{"Jam resolved."}

G92 E0      ; reset
M82     ; extruder in absolute

M98 P"/macros/fhx/control/mixratio.g" T{param.T}
M598

; resetting state            
set global.fhxMotorsRunning = null
; -----------------------------------------------------------------------------
M118 S{"[SENSOR CHECK] Done " ^var.CURRENT_FILE}
M99 ; proper exit