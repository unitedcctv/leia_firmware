; Description: 	
; This will set preload status and create pause before activating other motor while printing
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;	- T: Roll 0 or 1 to configure
;   Roll 0 = left, Roll 1 = rught
; Example:
;	M98 P"/macros/fhx/control/trigger/mixratio_status.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/fhx/control/trigger/mixratio_status.g"
M118 S{"[MR TRIGGER] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E71041

; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  Y{"Missing required input parameter T"} 	F{var.CURRENT_FILE} E71042
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E71043
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  Y{"Unexpected tool value"} 		F{var.CURRENT_FILE} E71044
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  Y{"Missing required input parameter S"} 	F{var.CURRENT_FILE} E71045
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E71046
M98 P"/macros/assert/abort_if.g" R{(param.S>=2||param.S<0)}  Y{"Unexpected Sensor value"} 		F{var.CURRENT_FILE} E71047
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxMotorsRunning)} 	Y{"Missing required motor status"} 	F{var.CURRENT_FILE} E71048
M98 P"/macros/assert/abort_if.g" R{(global.fhxMotorsRunning = 1)} 	Y{"machine busy"} 	F{var.CURRENT_FILE} E71049 ; machine loading
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_SENSOR_ID)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71050
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPreload)} 	Y{"Missing required sensors FHX"} 	F{var.CURRENT_FILE} E71051

if (global.fhxMotorsRunning == 3) ; machine know someone tried automatic preload while unloading
    set global.fhxMotorsRunning = 2 ; reset to unloading state so machine knows it is still in unloading
    M118 S{"[mixratio_status.g] machine busy"}
    M99 ; Proper exit
elif (global.fhxMotorsRunning == 2) ; triggered due to unload 
    set global.fhxMotorsRunning = null
    M98 P"/macros/fhx/control/mixratio.g" T{param.T}
    M118 S{"[mixratio_status.g] Done " ^var.CURRENT_FILE}
    M99 ; Proper exit
    
; Create variables-------------------------------------------------------------------------
var loopCounterOuter    = 0
var roll = null
var sens = null
var otherSens = null
var newMr = null

if (param.S = 0)
    set var.roll = "left spool"
    set var.sens = 1
    set var.newMr = {1,0,1}
    set var.otherSens = 3
else
    set var.roll = "right spool"
    set var.sens = 3
    set var.newMr = {1,1,0}
    set var.otherSens = 1

; cehcking state and changing MR------------------------------------------------------------
set global.fhxPreload[param.T][param.S] = false
M118 S{var.roll^"out of filament Tool"^param.T}

if (state.status == "processing")
    if ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.otherSens]].value == 0) || (global.fhxPreload[param.T][1 - param.S] = true))
        set var.loopCounterOuter = 0
        while ((sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 0) && (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens - 1]].value == 1) && (var.loopCounterOuter < 30))
            set var.loopCounterOuter = iterations
            G4 S2 ; wait 2 sec
        M400
        if ((var.loopCounterOuter >= 30) || (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens]].value == 1))
            M567 P{param.T} E{var.newMr}
    else 
        M98 P"/macros/fhx/control/mixratio.g" T{param.T}
    M400
    if (sensors.gpIn[global.FHX_SENSOR_ID[param.T][var.sens - 1]].value == 0) ; checking if customer preloaded right away
        M118 S{"Please check if Filament of preloaded Roll can still be pulled out and try Preload again if that is possible."}
        set global.fhxPreload[param.T][param.S] = true
else
    M98 P"/macros/fhx/control/mixratio.g" T{param.T}
M400
; -----------------------------------------------------------------------------
M118 S{"[mixratio_status.g] Done " ^var.CURRENT_FILE}
M99 ; Proper exit







