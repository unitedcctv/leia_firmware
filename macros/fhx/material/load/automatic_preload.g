; Description: 	
;	If Sensors detect change from inactive to active this will preload the fhx motors
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;  - S: Roll 0 or 1 
;        Roll 0: param.S = 0
;        Roll 1: param.S = 1
; Example:
;	M98 P"/macros/fhx/material/load/automatic_preload.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/material/load/automatic_preload.g"
M118 S{"[LOAD]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; emulator
if (network.hostname == "emulator") 
    set global.fhxPreload[param.T][param.S] = true
    M99

; Checking for files first---------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71072
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/safety/check.g"} F{var.CURRENT_FILE} E71073
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/enable_cold_extrusion.g"} F{var.CURRENT_FILE} E71074
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71075
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required OOF Sensor"} 	F{var.CURRENT_FILE} E71076
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71077
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71078
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71079
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71080
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71081
M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)}  Y{"Unexpected sensor value"} 		F{var.CURRENT_FILE} E71082
; motor state
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor state"} 	F{var.CURRENT_FILE} E71083
M98 P"/macros/assert/abort_if.g" R{(global.fhxMotorsRunning = 1)} 	Y{"machine busy"} 	F{var.CURRENT_FILE} E71084 ; machine loading
M98 P"/macros/assert/abort_if.g" R{(global.fhxMotorsRunning = 3)} 	Y{"machine busy"} 	F{var.CURRENT_FILE} E71085 ; someone tried automatic preload while unloading

if (global.fhxMotorsRunning = 2) ; machine unloading
    set global.fhxMotorsRunning = 3 ; set to 3 so the trigger knows user tried automatic preload
    M118 S{"machine busy"}
    M99 ; proper exit

; Definitions---------------------------------------------------------------------------------
var EXTRUSION_LENGTH_1          = 5             ; [mm]
var EXTRUSION_LENGTH_2          = -2            ; [mm]
var EXTRUSION_SPEED             = 1200          ; [mm/min]
var sens                        = null
var loopCounterOuter            = 0
var selectedRoll                = {""}          ; for error messages


; enable cold extrusion-----------------------------------------------------------
M98 P"/macros/extruder/enable_cold_extrusion.g"
M598

; set MR------------------------------------------------------------------------------------------------
if (param.S = 0)
    M567 P{param.T} E{0,1,0} ; motor 0
    M400
    set var.sens = 0
    set var.selectedRoll = {"T"^param.T^" left spool"}
else 
    M567 P{param.T} E{0,0,1} ; motor 1
    M400
    set var.sens = 2
    set var.selectedRoll = {"T"^param.T^" right spool"}

; preload------------------------------------------------------------------------------------------------
M83     ; extruder in relative      
G92 E0      ; reset extruder

if (param.T == 0)
    T0
    M400
else 
    T1
    M400

M98 P"/macros/report/event.g" Y{"Preloading %s"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71086

if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens + 1]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0))
    set var.loopCounterOuter = 0
    while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens + 1]].value == 1) && (var.loopCounterOuter < 40))
        set var.loopCounterOuter = iterations
        G1 E{var.EXTRUSION_LENGTH_1} F{var.EXTRUSION_SPEED}     ; while sensors 1 and 3 not triggered extrude to load motor
    if (var.loopCounterOuter >= 40)
        M302 P0 ; disable cold extrusion
        M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr for printing
        M598
        M98 P"/macros/assert/abort.g" Y{"Could not preload %s. Please remove filament, check inlet and feeder screws, then try again"} A{var.selectedRoll,}		F{var.CURRENT_FILE} E71086
    set var.loopCounterOuter = 0
    while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens + 1]].value == 0) && (var.loopCounterOuter < 60))
        set var.loopCounterOuter = iterations
        G1 E{var.EXTRUSION_LENGTH_2} F{var.EXTRUSION_SPEED}      ; retract until only 1 oe 3 are triggered to avoid filament collusion and be able to set mr 
    M400
    if (var.loopCounterOuter >= 60)
        M302 P0 ; disable cold extrusion
        M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr for printing
        M598
        M98 P"/macros/assert/abort.g" Y{"Could not preload %s. Please remove filament, check inlet and feeder screws, then try again"} 	A{var.selectedRoll,}	F{var.CURRENT_FILE} E71087
else 
    M98 P"/macros/report/event.g" Y{"Unexpected sensor response for %s. Please remove filament, check path and feeder screws, then try again"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71088
G92 E0      ; reset
M82     ; extruder in absolute

M302 P0 ; disable cold extrusion

; set mr print to be ready for printing-------------------------------------------------------------------------------------------
M98 P"/macros/fhx/control/mixratio.g" T{param.T} ; set mr for printing
M598

; checking filament path-----------------------------------------------------------------------------------------------------------
M98 P"/macros/fhx/control/safety/check.g" T{param.T} 
M598
if (global.fhxCheck = true)
    set global.fhxCheck = false
    set global.fhxMotorsRunning = null
    M98 P"/macros/assert/abort.g" Y{"Check filament path for %s"} A{var.selectedRoll,} F{var.CURRENT_FILE} E71089

M98 P"/macros/report/event.g" Y{"Done preloading %s"} A{var.selectedRoll,} F{var.CURRENT_FILE} V71090
; set preload status------------------------------------------------------------
set global.fhxPreload[param.T][param.S] = true
; -----------------------------------------------------------------------------
M118 S{"[LOAD] Done " ^var.CURRENT_FILE}
M99 ; proper exit