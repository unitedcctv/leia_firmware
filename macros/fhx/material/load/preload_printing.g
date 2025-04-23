; Description: 	
;	If Sensors detect change from inactive to active this will preload the fhx motors
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;   - S: Roll 0 or 1 
;        Roll 0: param.S = 0
;        Roll 1: param.S = 1
; Example:
;	M98 P"/macros/fhx/material/load/preload_printing.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/material/load/preload_printing.g"
M118 S{"[LOAD]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Definitions---------------------------------------------------------------------------------
; Checking for files first---------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71090
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/report/event.g"} F{var.CURRENT_FILE} E71091
; Checking global variables and input parameters ------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71092
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71093
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71094
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71095
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71096
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71097
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71098
M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)}  Y{"Unexpected sensor value"} 		F{var.CURRENT_FILE} E71099

; motor state
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor state"} 	F{var.CURRENT_FILE} E71100
M98 P"/macros/assert/abort_if.g" R{(global.fhxMotorsRunning = 1)} 	Y{"machine busy"} 	F{var.CURRENT_FILE} E71101 ; machine loading
M98 P"/macros/assert/abort_if.g" R{(global.fhxMotorsRunning = 3)} 	Y{"machine busy"} 	F{var.CURRENT_FILE} E71102 ; someone tried autmatic preload while unloading

; emulator
if (network.hostname == "emulator") 
    set global.fhxPreload[param.T][param.S] = true
    M99

; checking lower sensor to see if the path is clear
;if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][param.S]].value == 0)
;    M98 P"/macros/assert/abort.g" Y{"Please wait until filament path is clear or preload other roll first if both rolls are out of filament."} 		F{var.CURRENT_FILE} E71103 

; Create variables------------------------------------------------------------------------
var mrOther             = null          ; tools[param.T].mix  ; current mix ratio
var mrNew               = null          ; Mix ratio to switch to preloaded roll
var sensOther           = null          ; sensor number other roll 
var Sensor              = null          ; Mix ratio to switch to preloaded roll
;var currentMr           = tools[param.T].mix
var loopCounterOuter            = 0

if (param.S == 0) ; left roll will preload 
   set var.sensOther = 3
   set var.Sensor = 0
   set var.mrNew = {1,1,0}
   set var.mrOther = {1,0,1}
else 
   set var.sensOther = 1
   set var.Sensor = 2
   set var.mrNew = {1,0,1}
   set var.mrOther = {1,1,0}

; starting preload------------------------------------------------------------------------------  
if (global.fhxPreload[param.T][param.S] = true)
    M118 S{"[LOAD] Done " ^var.CURRENT_FILE}
    M99

if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensOther]].value == 1) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensOther -1]].value == 1))
    M567 P{param.T} E{var.mrNew} ; if other roll is empy so customer can´t preload two rolls, as this might cause a jam, trigger will preload other roll after first one is preloaded
elif ((global.fhxPreload[param.T][1 - param.S] = true) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.Sensor + 1]].value == 0))
    M567 P{param.T} E{var.mrNew}
else 
    M567 P{param.T} E{1,1,1} ; all motors

G4 S6 ; wait 6 sec
M400

if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.Sensor]].value == 0) ; filament for preloaded roll is detected
    set global.fhxPreload[param.T][param.S] = true ; setting preload status
    if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.Sensor + 1]].value == 1)    ; checking if path for preloaded roll is free
        if (global.fhxPreload[param.T][1 - param.S] == true) ; checking if other roll was printing
            M567 P{param.T} E{var.mrOther} ; set back to roll that was preloaded already
        else
            if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensOther]].value == 0) ; edge case cross sensor activation
                M567 P{param.T} E{var.mrOther} ; set to roll that has leftover filament in fhx system
                set var.loopCounterOuter = 0
                while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensOther]].value == 0) && (var.loopCounterOuter < 15)) ; creating gap before switching to new roll
                    set var.loopCounterOuter = iterations
                    G4 S2 ; wait 2 sec
                M400
            M567 P{param.T} E{var.mrNew} ; set new ratio to continue pritning with new roll other roll is empty as well
    else
        if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sensOther]].value == 1) ; other roll either empty or not in sensor yet, preloaded roll will be selected
            M567 P{param.T} E{var.mrNew}
        else 
            M98 P"/macros/report/event.g" Y{"Pausing due to filament jam wait for further instructions."} F{var.CURRENT_FILE} V72105
            M567 P{param.T} E{0,0,0}
            M25	; Pausing, pause calls safety
            M400 ; finishing moves
else
    M98 P"/macros/fhx/control/mixratio.g" T{param.T}
    M598 
    M98 P"/macros/assert/abort.g" Y{"Roll did not preload, please try again." } F{var.CURRENT_FILE} E71104

M118 S{"Please check if Filament of preloaded Roll can still be pulled out and try Preload again if that is possible."} 

;----------------------------------------------------------------------------------------------------
M118 S{"[LOAD] Done " ^var.CURRENT_FILE}
M99








