; Description: 	
;	called (by load, pause, load extruder and preload) if unwanted sensor activation is detected 
; Example:
;	M98 P"/macros/fhx/control/safety/check.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/safety/check.g"
M118 S{"[SENSOR CHECK] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/safety/scenario_s13.g"} F{var.CURRENT_FILE} E71014
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/report/event.g"} F{var.CURRENT_FILE} E71015
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/safety/scenario_across.g"} F{var.CURRENT_FILE} E710016
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71017
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71018
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71019
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors Infinity box"} 	F{var.CURRENT_FILE} E71020
M98 P"/macros/assert/abort_if.g" R{!exists(global.oofFhxSensorID)} 	Y{"Missing required oof Sensor ID"} 	F{var.CURRENT_FILE} E71021
M98 P"/macros/assert/abort_if.g" R{!exists(global.OOF_TRIGG_VALUE)} 	Y{"Missing required oof trigg value"} 	F{var.CURRENT_FILE} E71022
; set variables------------------------------------------
var errorBay    = null

if (!exists(global.fhxCheck))
	global fhxCheck = false
else 
	set global.fhxCheck = false
; emulator
if (network.hostname == "emulator")   
	M99
; variables to check sensors 
var S03val0 = ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][0]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0))
var S03val1 = ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][0]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 1))
var S12val0 = ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][2]].value == 0))
var S12val1 = ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][2]].value == 1))
var S13val0 = ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 0)) 

; checking sensors---------------------------------------------

if (var.S13val0 == true) ; Checking if 1 and 3 are activated
	M98 P"/macros/fhx/control/safety/scenario_s13.g" T{param.T}
	M598
elif (((var.S03val1 == true) && (var.S12val0 == true)) || ((var.S03val0 == true) && (var.S12val1 == true))) ; Sensors across from each other are activated others deactivated 
	if (sensors.analog[global.oofFhxSensorID[param.T]].lastReading >= (global.OOF_TRIGG_VALUE))     ; filament not in extruder filament broke or got stuck
		if ((var.S03val1 == true) && (var.S12val0 == true))
			set var.errorBay = "T0 Box"
		elif ((var.S03val0 == true) && (var.S12val1 == true))
			set var.errorBay = "T1 Box"
		set global.fhxCheck = true
		M98 P"/macros/report/event.g" Y{"filament stuck in %s, please go to mainantance and try to purge material."} A{var.errorBay,} F{var.CURRENT_FILE} V72101
	elif (sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE))  ; this could happen if a customer decides to load the other roll while the first is still in the merger
		M98 P"/macros/fhx/control/safety/scenario_across.g" T{param.T}

; -----------------------------------------------------------------------------
M118 S{"[SENSOR CHECK] Done " ^var.CURRENT_FILE}
M99 ; proper exit