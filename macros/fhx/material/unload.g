; Description: 	
;	This will unload selected roll
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;  - S: Roll 0 or 1 
;        Roll 0: param.S = 1
;        Roll 1: param.S = 3
; Example:
;	M98 P"/macros/fhx/material/unload.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/material/unload.g"
M118 S{"[UNLOAD] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71129

; Checking for files first------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71130
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/enable_cold_extrusion.g"} F{var.CURRENT_FILE} E71131
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/hmi/material/unload.g"} F{var.CURRENT_FILE} E71132
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71133
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71134
M98 P"/macros/assert/abort_if.g" R{!exists(global.oofFhxSensorID)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71135
M98 P"/macros/assert/abort_if.g" R{!exists(global.OOF_TRIGG_VALUE)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71136
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71137
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71138
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71139
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71140
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71141
M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)}  Y{"Unexpected sensor value"} 		F{var.CURRENT_FILE} E71142

; set motor state 
set global.fhxMotorsRunning = 2

; Definitions-------------------------------------------------------------------------
var EXTRUSION_LENGTH             = 20     ; [mm]
var EXTRUSION_SPEED              = 3*60   ; [mm/min]
var RETRACTION_LENGTH_1          = -71    ; [mm]
var RETRACTION_LENGTH_2          = -38    ; [mm]
var RETRACTION_LENGTH_LOOP       = -5     ; [mm]
var RETRACTION_SPEED_EXTRUDER    = 40*60  ; [mm/min]
var RETRACTION_SPEED             = 3000   ; [mm/min]
var RETRACTION_LENGTH_3          = -250   ; [mm]
var loopCounterOuter             = 0
var sens                         = null   ; sensor 
var selectedRoll                 = {""}

if (param.S == 0)
   set var.selectedRoll = {"T"^param.T^" left spool"}
   set var.sens = 1
else 
   set var.selectedRoll = {"T"^param.T^" right spool"}
   set var.sens = 3

; emulator
if (network.hostname == "emulator")
   set global.fhxPreload[param.T][param.S] = false
   M118 S{"#xza# Done unloading %s. You can remove the filament now | In file /macros/fhx/material/unload.g | {"^var.selectedRoll^"}"}
   M118 S{"[UNLOAD] Done " ^var.CURRENT_FILE}
   M99
M400

;var ROLL0_EMPTY = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][0]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][1]].value == 1)
;var ROLL1_EMPTY = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][2]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][3]].value == 1)
;var ROLL_EMPTY = {null, var.ROLL0_EMPTY, null, var.ROLL1_EMPTY}
;var UNLOAD_EXTRUDER = ((sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)) && var.ROLL0_EMPTY && var.ROLL1_EMPTY)
   
; Check for filament --------------------------------------------------------------
;if ((sensors.analog[global.oofFhxSensorID[param.T]].lastReading >= (global.OOF_TRIGG_VALUE)) && (var.ROLL_EMPTY == true)) ; is this needed should be checked in hmi
;   set global.fhxMotorsRunning = null
;   M98 P"/macros/assert/abort.g" Y{""^var.selectedRoll^" Tool " ^param.T^ "is not loaded"}  F{var.CURRENT_FILE} E71143 

; unload----------------------------------------------------------------------------
M83     ; extruder in relative      
G92 E0      ; reset extruder 

; unloading selected roll
if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 1) && (global.fhxPreload[param.T][param.S] == true ))
   M98 P"/macros/extruder/enable_cold_extrusion.g"
   M400
   if (param.S == 0)
      M567 P{param.T} E0:1:0 ; setting Mix ratio to roll 0
      M400
   else
      M567 P{param.T} E0:0:1 ; setting Mix ratio to roll 1
      M400
   G1 E{var.RETRACTION_LENGTH_3} F{var.RETRACTION_SPEED}
   M400
   M302 P0 ; disable cold extrusion
   set global.fhxPreload[param.T][param.S] = false 
   M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr print to be ready for printing
   set global.fhxMotorsRunning = null  ; set motor state
   M98 P"/macros/report/event.g" Y{"Done unloading %s. You can remove the filament now"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71140
   M118 S{"[UNLOAD] Done " ^var.CURRENT_FILE}
   M99 ; Proper exit
M400

if (param.S == 0)
   M567 P{param.T} E{1,1,0} ; setting Mix ratio to roll 0
else
   M567 P{param.T} E{1,0,1} ; setting Mix ratio to roll 1
M400

if ((sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0) && (global.fhxPreload[param.T][param.S] == true ))  ; extruder loaded with selected roll
   G1 E{var.EXTRUSION_LENGTH} F{var.EXTRUSION_SPEED}
   G1 E{var.RETRACTION_LENGTH_1} F{var.RETRACTION_SPEED_EXTRUDER} ; Retract 71mm with 40mm/s, in mm/min
   M400
   M98 P"/macros/report/event.g" Y{"Cooling down filament for 30 seconds. Please stand by"} F{var.CURRENT_FILE} V71141
   M400
   G4 S30 ; wait 30 sec
   M400
   G1 E{var.RETRACTION_LENGTH_2 * 2} F{var.RETRACTION_SPEED_EXTRUDER} ; Retract 38mm with 40mm/s, in mm/min
M400

if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens - 1]].value == 0))
   M98 P"/macros/report/event.g" Y{"Fully unloading %s. Please respool manually as the filament is ejected"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71142
   set var.loopCounterOuter = 0
   while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0) && (var.loopCounterOuter < 1000))
      set var.loopCounterOuter = iterations ; Increment the iterations variable 
      G1 E{var.RETRACTION_LENGTH_LOOP} F{var.RETRACTION_SPEED}
   M400 
   if (var.loopCounterOuter >= 1000)
      set global.fhxMotorsRunning = null
      M98 P"/macros/assert/abort.g" Y{"Unload Timeout for %s. Filament may be stuck in tube"} A{var.selectedRoll,} F{var.CURRENT_FILE} E71144
   G1 E{var.RETRACTION_LENGTH_3} F{var.RETRACTION_SPEED}
M400

G92 E0      ; reset
M82     ; extruder in absolute

var ROLL_EMPTY = (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens - 1]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 1)

if ((sensors.analog[global.oofFhxSensorID[param.T]].lastReading < (global.OOF_TRIGG_VALUE)) && var.ROLL_EMPTY)
   M567 P{param.T} E{1,0,0} ; setting Mix ratio to roll 0
   M400
   M98 P"/macros/hmi/material/unload.g" T{param.T}
M400

; checking result (if sensors 1, 3 or oof still detect filament the path is not free and the filament needs to be removed by user)
if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0)
   set global.fhxMotorsRunning = null
   M98 P"/macros/assert/abort.g" Y{"Filament may be stuck in tube. Please check filament path for %s"} A{var.selectedRoll,}  F{var.CURRENT_FILE} E71145

set global.fhxPreload[param.T][param.S] = false

; set mr print to be ready for printing------------------------------------------------------
M98 P"/macros/fhx/control/mixratio.g" T{param.T} 

; set motor state
set global.fhxMotorsRunning = null

M98 P"/macros/report/event.g" Y{"Done unloading %s"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71143

; -----------------------------------------------------------------------------
M118 S{"[UNLOAD] Done " ^var.CURRENT_FILE}
M99 ; Proper exit
