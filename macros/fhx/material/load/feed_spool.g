; Description: 	
;	this will load selected roll to extruder after preload
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;  - S: Roll 0 or 1 
;        Roll 0: param.S = 0
;        Roll 1: param.S = 1
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/material/load/feed_spool.g"
M118 S{"[feed_spool.g]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; emulator
if (network.hostname == "emulator") 
	set global.fhxPreload[param.T][param.S] = true
	M99

; Checking for files first------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71105
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/safety/check.g"} F{var.CURRENT_FILE} E71106
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/sensors/find_by_name.g"} F{var.CURRENT_FILE} E71107
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71108
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required FHX_SENSOR_IDORS"} 	F{var.CURRENT_FILE} E71148
M98 P"/macros/assert/abort_if.g" R{!exists(global.oofFhxSensorID)} 	Y{"Missing required OOF Sensor"} 	F{var.CURRENT_FILE} E71110
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required OOF Sensor"} 	F{var.CURRENT_FILE} E71111
M98 P"/macros/assert/abort_if.g" R{!exists(global.OOF_TRIGG_VALUE)} 	Y{"Missing required OOF Sensor"} 	F{var.CURRENT_FILE} E71112
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71113
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71114
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71115
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71116
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71117
M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)}  Y{"Unexpected sensor value"} 		F{var.CURRENT_FILE} E71118

; set motor state 
set global.fhxMotorsRunning = 1

; Define variables-----------------------------------------------------------------------
var EXTRUSION_LENGTH_TEST       = 20    ; [mm]
var EXTRUSION_SPEED_FAST        = 3000  ; [mm/min] (40 mm/s)
var EXTRUSION_LENGTH_LOOP       = 5     ; [mm]
var FEED_LENGTH_LONG 		    = 4000  ; [mm]
var EXTRUSION_SPEED_LOOP        = 600   ; [mm/min] (10 mm/s)
var LOOP_ITERATIONS			    = floor(var.FEED_LENGTH_LONG / var.EXTRUSION_LENGTH_LOOP); try to keep it modulo 0
var EXTRUSION_LENGTH_EXTRUDER   = 100   ; [mm]
var EXTRUSION_SPEED_EXTRUDER    = 180   ; [mm/min] (3 mm/s)
var MIN_EX 			            = 10    ; [mm]
var bottomSensorIndexThis          = null  ; sensor number
var bottomSensorIndexOther         = null
var mrBoxExtruder             = null
var mrBox                       = null
var loopCounterOuter            = 0    
var spoolName                = ""

if (param.S == 0)
	set var.spoolName = {"T"^param.T^" left spool"}
	set var.bottomSensorIndexThis = 1
	set var.bottomSensorIndexOther = 3
	set var.mrBoxExtruder = {1,1,0}
	set var.mrBox = {0,1,0}
else 
	set var.spoolName = {"T"^param.T^" right spool"}
	set var.bottomSensorIndexThis = 3
	set var.bottomSensorIndexOther = 1
	set var.mrBoxExtruder = {1,0,1}
	set var.mrBox = {0,0,1}

var filamentThisBottom = sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.bottomSensorIndexThis]].value == 0
var filamentThisTop = global.fhxPreload[param.T][param.S] == true

var filamentOtherBottom = sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.bottomSensorIndexOther]].value == 0
var filamentOtherTop = global.fhxPreload[param.T][1 - param.S] == true

var THIS_LOADED = var.filamentThisBottom && var.filamentThisTop
var OTHER_LOADED = var.filamentOtherBottom && var.filamentOtherTop



var hasFilamentExtruder = sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)

M118 S{"[feed_spool.g] Loading " ^var.spoolName}

; check-------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{(global.fhxPreload[param.T][param.S] == false)}  Y{"no filament to be loaded"} 		F{var.CURRENT_FILE} E71119

if (var.OTHER_LOADED)
	set global.fhxMotorsRunning = null
	M98 P"/macros/assert/abort.g" Y{"Other spool is already loaded"}  F{var.CURRENT_FILE} E71120

M98 P"/macros/fhx/control/safety/check.g" T{param.T} ; sensor response
M598
if (global.fhxCheck = true)
	set global.fhxMotorsRunning = null
	set global.fhxCheck = false
	M98 P"/macros/assert/abort.g" Y{"Check filament path for %s"} A{var.spoolName,} F{var.CURRENT_FILE} E71151

; if the extruder already has filament, only load up to bottom sensor and exit
if (var.hasFilamentExtruder)
	if (var.filamentThisBottom) ; roll already loaded
		set global.fhxMotorsRunning = null
		;M98 P"/macros/assert/abort.g" Y{"%s is already loaded, cannot load again"} A{var.spoolName,} F{var.CURRENT_FILE} E71149

	elif (!var.filamentThisBottom && !var.filamentOtherBottom)
		M567 P{param.T} E{var.mrBox} ; set mixing ratio to only box
		G1 E{var.EXTRUSION_LENGTH_LOOP * 15} F{var.EXTRUSION_SPEED_FAST} ; feed up to bottom sensor
		M400
		M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr for printing
		M598
		set global.fhxPreload[param.T][param.S] = true
		set global.fhxMotorsRunning = null
		M118 S{"[feed_spool.g] Done " ^var.CURRENT_FILE}
		M99
	M400
M400

; load extruder--------------------------------------------------------------------------------
M83     ; extruder in relative      
G92 E0      ; reset extruder 

if (!var.filamentThisBottom && !var.hasFilamentExtruder) ; no filament in filament path can load quick
	M567 P{param.T} E{var.mrBox}  ; set mixing ratio to only box
	M98 P"/macros/report/event.g" Y{"Feeding filament up to extruder. This process takes about 2 minutes"} F{var.CURRENT_FILE} V71150
	; no filament in extruder and box, loading 4000 mm
	while iterations <= var.LOOP_ITERATIONS
		G1 E{var.EXTRUSION_LENGTH_LOOP} F{var.EXTRUSION_SPEED_FAST}
		set var.hasFilamentExtruder = sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)
		if (var.hasFilamentExtruder)
			break
	M400
M400


set var.filamentThisBottom = sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.bottomSensorIndexThis]].value == 0

if (!var.hasFilamentExtruder && var.filamentThisBottom)
	M567 P{param.T} E{var.mrBoxExtruder}  ; set mixing ratio to extruder and box
	set var.loopCounterOuter = 0
	while iterations < 850 ; no filament in extruder, loading until it reaches oof
		G1 E{var.EXTRUSION_LENGTH_LOOP} F{var.EXTRUSION_SPEED_LOOP}
		set var.hasFilamentExtruder = sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)
		if (var.hasFilamentExtruder)
			break
	M400
	G1 E{var.EXTRUSION_LENGTH_EXTRUDER} F{var.EXTRUSION_SPEED_EXTRUDER}     ; filament reached extruder, extrude a little to make sure it reaches nozzle
M400
G92 E0      ; reset
M82     ; extruder in absolute

; check for filament collision ---------------------------------------------------
M98 P"/macros/fhx/control/safety/check.g" T{param.T} 
M598
if (global.fhxCheck = true)
	set global.fhxCheck = false
	set global.fhxMotorsRunning = null
	M98 P"/macros/assert/abort.g" Y{"Could not load. Check filament path for %s"}  A{var.spoolName,} F{var.CURRENT_FILE} E71126

; set mr print to be ready for printing------------------------------------------------------
M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr for printing

; making sure filament is loaded properly by verifying that we are extruding-----------------
; finding sensor
M98 P"/macros/sensors/find_by_name.g" N{"fila_accu_t"^param.T^"[mm]"}
var FILA_ACCU_SENSOR_ID = global.sensorIndex
var FILA_ACCU_BASELINE = (sensors.analog[var.FILA_ACCU_SENSOR_ID].lastReading)

M98 P"/macros/report/event.g" Y{"Verifying extrusion"} F{var.CURRENT_FILE} V71126
G1 E{var.EXTRUSION_LENGTH_TEST} F{var.EXTRUSION_SPEED_EXTRUDER} 
M400

var FILA_ACCU_POST_EXTRUSION = (sensors.analog[var.FILA_ACCU_SENSOR_ID].lastReading)
var EXTRUDED_AMOUNT = (var.FILA_ACCU_POST_EXTRUSION - var.FILA_ACCU_BASELINE)
M118 S{"[feed_spool.g] Extruded mm: " ^var.EXTRUDED_AMOUNT}

; checking result
if (var.EXTRUDED_AMOUNT < var.MIN_EX)
	set global.fhxMotorsRunning = null
	M98 P"/macros/assert/abort.g" Y{"Too little extrusion after loading T%s, please check for clogging"} A{param.T,}  F{var.CURRENT_FILE} E71127

set global.fhxPreload[param.T][param.S] = true

; set motor state
set global.fhxMotorsRunning = null
var SPOOL_SIDE = (param.S == 0) ? "left" : "right"
M98 P"/macros/report/event.g" Y{"T%s %s spool loaded successfully"} A{param.T,var.SPOOL_SIDE} F{var.CURRENT_FILE} V71127
; -----------------------------------------------------------------------------
M118 S{"[feed_spool.g] Done " ^var.CURRENT_FILE}
M99 ; proper exit
