; Description: 	
;	called (by load, pause, load extruder and preload) if unwanted sensor activation is detected 
; Example:
;	M98 P"/macros/fhx/control/safety/scenario_s13.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/safety/scenario_s13.g"
M118 S{"[SENSOR CHECK] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/recover_tool_temp.g"} F{var.CURRENT_FILE} E71031
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71032
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71033
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71034
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71035
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71036
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71037
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxCheck)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71038
M98 P"/macros/assert/abort_if.g" R{!exists(global.oofFhxSensorID)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71039
M98 P"/macros/assert/abort_if.g" R{!exists(global.OOF_TRIGG_VALUE)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71040

; set variables------------------------------------------
var RETRACTION_LENGTH      = -5    ; mm 
var RETRACTION_SPEED       = 350   ; [mm/m] = 5 mm/s
var EXTRUSION_LENGTH       = 10    ; mm
var EXTRUSION_SPEED        = 120   ; [mm/m] = 2 mm/s
var loopCounterOuter       = 0

if ((sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)) && ((state.status == "pausing") || (state.status == "paused")))
	M98 P"/macros/printing/recover_tool_temp.g" ; checking if the extruder is still hot
	M116
	M598

; resolving jam-------------------------------------------------------------
set global.fhxMotorsRunning = 2

M83     ; extruder in relative      
G92 E0      ; reset extruder

M567 P{param.T} E{1,1,1} ; all motors need to retract
M118 S{"resolving filament jam, please wait"}
while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0) && (var.loopCounterOuter < 20))
	set var.loopCounterOuter = iterations
	G1 E{var.RETRACTION_LENGTH} F{var.RETRACTION_SPEED} ; retracting until at least one sensor is not activated
M400
if (((sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0)) || (var.loopCounterOuter >= 20))
	M0 
	M400
	set global.fhxCheck = true 
	M98 P"/macros/report/event.g" Y{"Filament stuck, please unload preloaded roll and check the filament path to Tool %s"} A{param.T,} F{var.CURRENT_FILE} V72100
else
	M98 P"/macros/fhx/control/mixratio.g" T{param.T}
	M598
	G1 E{var.EXTRUSION_LENGTH * var.loopCounterOuter} F{var.EXTRUSION_SPEED}  
	G1 E{var.EXTRUSION_LENGTH} F{var.EXTRUSION_SPEED} 
	M400
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