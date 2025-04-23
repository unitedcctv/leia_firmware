; NOTE: The direction of the motor driver (M569) must be set before calling this macro.
;	
; Input parameters:
;	- D: [] Driver ( Only 0.5, 0.6, 81.0 or 82.0 are supported )
;   - I: [] microstepping
;	- T: [steps/mm] Steps per mm 
;	- J  [mm/min] Jerk
;	- S: [mm/min] Maximum Speed
;	- A: [mm/s^2] Acceleration 	
; 	- C: [mA] Current
; Output parameters:
;	- global.extruderDriverId : Driver ID to use to create the tool. If there 
;								is an error it will be 'null'.
; TODO:
;	1. Once arrays are supported, add the drivers port (M584) to an array
;	as in the OM is shown as a string.
;	2. Support M584 call properly. There is a byg with variables and array.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/automatic_detection.g"
M118 S{"[TOOL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.D)}  			Y{"Missing required input parameter D"} F{var.CURRENT_FILE} E57030
M98 P"/macros/assert/abort_if_null.g" R{param.D}  	  			Y{"Input parameter D is null"} 			F{var.CURRENT_FILE}	E57031
M98 P"/macros/assert/abort_if.g" R{!exists(param.I)}  			Y{"Missing required input parameter I"} F{var.CURRENT_FILE} E57032
M98 P"/macros/assert/abort_if_null.g" R{param.I}  	  			Y{"Input parameter I is null"} 			F{var.CURRENT_FILE} E57033
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  			Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E57034
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  			Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E57035
M98 P"/macros/assert/abort_if.g" R{!exists(param.J)}  			Y{"Missing required input parameter J"} F{var.CURRENT_FILE} E57036
M98 P"/macros/assert/abort_if_null.g" R{param.J}  	  			Y{"Input parameter J is null"} 			F{var.CURRENT_FILE} E57037
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)}  			Y{"Missing required input parameter S"} F{var.CURRENT_FILE} E57038
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  			Y{"Input parameter S is null"} 			F{var.CURRENT_FILE} E57039
M98 P"/macros/assert/abort_if.g" R{!exists(param.A)}  			Y{"Missing required input parameter A"} F{var.CURRENT_FILE} E57040
M98 P"/macros/assert/abort_if_null.g" R{param.A}  	  			Y{"Input parameter A is null"} 			F{var.CURRENT_FILE} E57041
M98 P"/macros/assert/abort_if.g" R{!exists(param.C)}  			Y{"Missing required input parameter C"} F{var.CURRENT_FILE} E57042
M98 P"/macros/assert/abort_if_null.g" R{param.C}  	  			Y{"Input parameter C is null"} 			F{var.CURRENT_FILE} E57043
; Checking the driver
var INVALID_DRIVER = (param.D != 0.5 && param.D != 0.6 && param.D != 81.0 && param.D != 82.0)
M98 P"/macros/assert/abort_if.g" R{var.INVALID_DRIVER}  		Y{"Only drivers 0.5, 0.6, 81.0 or 82.0 are supported"} F{var.CURRENT_FILE} E57045


; Default values of the return parameter
var EXTRUDERS_CONFIGURED = {(!exists(global.extruderDriverId) ? 0 : (global.extruderDriverId+1) ) }; Amount of extruders currently available
M98 P"/macros/assert/abort_if.g" R{(var.EXTRUDERS_CONFIGURED > 1)} Y{"No more extruders can be configured"} F{var.CURRENT_FILE} E57046
if(!exists(global.extruderDriverId))
	global extruderDriverId = null
else
	set global.extruderDriverId = null

; Checking the driver name
var DRIVER_NAME = { (param.D < 1) ? {""^{floor(param.D*10)}} : {""^{param.D}} }	; Cast to driver number to string
while (iterations < #move.extruders)
	if(move.extruders[iterations] != null && move.extruders[iterations].driver != null)
		M98 P"/macros/assert/abort_if.g" R{(move.extruders[iterations].driver == var.DRIVER_NAME)} Y{"Driver already used"} F{var.CURRENT_FILE} E57047

if( param.D == 81.0 || param.D == 82.0)
	M569 P{param.D} D3 H50 V50 ; We need stealthChop to enable the sensor

if( var.EXTRUDERS_CONFIGURED == 0 )
	; Mapping
	M584 E{param.D}		; Mapping the extruder 0 to param.D
	M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor driver to T0" F{var.CURRENT_FILE} E57048
	; Microstepping
	M350 E{param.I} 		; Configure microstepping without interpolation in T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in T0" F{var.CURRENT_FILE} E57049
	; Steps per mm
	M92  E{param.T} 		; [step/mm] Set steps per mm in T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in T0" F{var.CURRENT_FILE} E57050
	; Maximum instantaneous speed changes
	M566 E{param.J}	; [mm/min] Set maximum instantaneous speed changes in T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk in T0" F{var.CURRENT_FILE} E57051
	; Maximum speeds
	M203 E{param.S} 	; [mm/min] Set maximum speeds in T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in T0" F{var.CURRENT_FILE} E57052
	; Accelerations
	M201 E{param.A} 	; [mm/s^2] Set acceleration in T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the accelerations in T0" F{var.CURRENT_FILE} E57053
	; Current and idle factor
	M906 E{param.C}	I{move.idle.factor*100} ; [mA][%] Set motor currents and motor idle factor in per cent in X
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current on idle factor in T0 driver" F{var.CURRENT_FILE} E57054
	set global.extruderDriverId = 0	; return
else
	var otherDriver = 0.0
	if( move.extruders[0].driver == "5" && param.D == 0.6 )
		set var.otherDriver = 0.5		; Emulator
		M584 E0.5:0.6					; Mapping the extruder 1 to param.D
		M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor driver to T1" F{var.CURRENT_FILE} E57055
	elif( move.extruders[0].driver == "6" && param.D == 0.5 )
		M584 E0.6:0.5					; Mapping the extruder 1 to param.D
		M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor driver to T1" F{var.CURRENT_FILE} E57056
	elif( move.extruders[0].driver == "81.0" && param.D == 82.0 )
		M584 E81.0:82.0					; Mapping the extruder 1 to param.D
		M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor driver to T1" F{var.CURRENT_FILE} E57057
	elif( move.extruders[0].driver == "82.0" && param.D == 81.0 )
		M584 E82.0:81.0					; Mapping the extruder 1 to param.D
		M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor driver to T1" F{var.CURRENT_FILE} E57058
	else
		M98 P"/macros/assert/abort.g" Y{"Unknown first exturder driver or not supported"}  F{var.CURRENT_FILE} E57059
	; Mapping
	; Microstepping
	M350 E{move.extruders[0].microstepping.value}:{param.I} 		; Configure microstepping without interpolation in T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in T1" F{var.CURRENT_FILE} E57060
	; Steps per mm
	M92  E{move.extruders[0].stepsPerMm}:{param.T} 		; [step/mm] Set steps per mm in T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in T1" F{var.CURRENT_FILE} E57061
	; Maximum instantaneous speed changes
	M566 E{move.extruders[0].jerk}:{param.J}	; [mm/min] Set maximum instantaneous speed changes in T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk in T1" F{var.CURRENT_FILE} E57062
	; Maximum speeds
	M203 E{move.extruders[0].speed}:{param.S} 	; [mm/min] Set maximum speeds in T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in T1" F{var.CURRENT_FILE} E57063
	; Accelerations
	M201 E{move.extruders[0].acceleration}:{param.A} 	; [mm/s^2] Set acceleration in T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the accelerations in T1" F{var.CURRENT_FILE} E57064
	; Current and idle factor
	M906 E{move.extruders[0].current}:{param.C}	I{move.idle.factor*100} ; [mA][%] Set motor currents and motor idle factor in per cent in X
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current on idle factor in T1 driver" F{var.CURRENT_FILE} E57065
	set global.extruderDriverId = 1 ; return

; -----------------------------------------------------------------------------
M118 S{"[TOOL] Done "^var.CURRENT_FILE}
M99 ; Proper exit