; Description:
;	We control the 230V with this module.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/emulator/config.g"
M118 S{"[CONFIG]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking Files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/fhx/emulator/sensors.g"} F{var.CURRENT_FILE} E17656
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_FHX)}  	 Y{"A previous infinity box configuration exists"} 	F{var.CURRENT_FILE} E17660

; DEFINITIONS --------------------------------------------------------------------------------
var FHX_POWER_PORT = "0.fan2"		; variable to store the Pin id of the FHX power controller
M98 P"/macros/get_id/output.g"
global FHX_POWER_OUTPUT = global.outputId	; variable to store the output id of the FHX power controller

global fhxPowerIsEnabled = 0  ; Variable to store the current status of the FHX-Power:
							  ;	 0 : It is OFF
							  ;	 1 : It is ON
var PRESSURE_ADVANCE_FHX = 0.07	; [sec] Pressure advance to use in the extruders (M572)

; CONFIGURATION ---------------------------------------------------------------
; Power output
M950 P{global.FHX_POWER_OUTPUT} C{var.FHX_POWER_PORT} Q1
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the FHX power output"  F{var.CURRENT_FILE} E17663

; Checking if there are extruders
var HAS_EXTRUDER_0 = (exists(global.MODULE_EXTRUDER_0) && global.MODULE_EXTRUDER_0 > 0)
var HAS_EXTRUDER_1 = (exists(global.MODULE_EXTRUDER_1) && global.MODULE_EXTRUDER_1 > 0)

var T0_IDX = { var.HAS_EXTRUDER_0 ? tools[0].extruders[0] : null }
var T1_IDX = { var.HAS_EXTRUDER_1 ? tools[1].extruders[0] : null }

; Configuration values --------------------------------------------------------
var MICROSTEPPINGS 	= { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].microstepping.value 	: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].microstepping.value : null } }
var STEPS_PER_MM  	= { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].stepsPerMm 			: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].stepsPerMm 			: null } }
var JERKS          	= { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].jerk 					: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].jerk 				: null } }
var SPEEDS  	    = { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].speed 				: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].speed 				: null } }
var ACCELERATIONS  	= { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].acceleration 			: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].acceleration 		: null } }
var CURRENTS  		= { { var.HAS_EXTRUDER_0 ? move.extruders[var.T0_IDX].current 			  	: null }, { var.HAS_EXTRUDER_1 ? move.extruders[var.T1_IDX].acceleration 		: null } }


var moduleFhx0 = null
var moduleFhx1 = null

global MODULE_FHX = {var.moduleFhx0, var.moduleFhx1}

if (var.HAS_EXTRUDER_1)
	; snensors and trigger links
	M98 P"/sys/modules/fhx/emulator/sensors.g" T1
	; We have FHX box only for T1 and there is no T0 ----------------------
	; Set drive mapping
	M584 E0.6:0.9:0.10
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the motor-mapping with infinity box 1 for T1" F{var.CURRENT_FILE} E17696
	;set drive mapping
	M350 E{var.MICROSTEPPINGS[1]}:{var.MICROSTEPPINGS[1]}:{var.MICROSTEPPINGS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping with infinity box" F{var.CURRENT_FILE} E17697
	; Steps per mm
	M92  E{var.STEPS_PER_MM[1]}:{var.STEPS_PER_MM[1]}:{var.STEPS_PER_MM[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm with infinity box" F{var.CURRENT_FILE} E17700
	; Maximum instantaneous speed changes
	M566 E{var.JERKS[1]}:{var.JERKS[1]}:{var.JERKS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk with infinity box" F{var.CURRENT_FILE} E17701
	; Maximum speeds
	M203 E{var.SPEEDS[1]}:{var.SPEEDS[1]}:{var.SPEEDS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the speed with infinity box" F{var.CURRENT_FILE} E17702
	; Accelerations
	M201 E{var.ACCELERATIONS[1]}:{var.ACCELERATIONS[1]}:{var.ACCELERATIONS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the acceleration with infinity box" F{var.CURRENT_FILE} E17703
	; Current and idle factor
	M906 E{var.CURRENTS[1]}:{var.CURRENTS[1]}:{var.CURRENTS[1]} I{move.idle.factor*100} ; [mA][%] Set motor currents and motor idle factor in per cent in X
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current with infinity box" F{var.CURRENT_FILE} E17704
	; Redifine the tools
	M563 P1 D0:1:2 H{tools[1].heaters[0]} F{tools[1].fans[0]} S{tools[1].name} ; ReDefine tool
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine T" F{var.CURRENT_FILE} E17705
	; Setting the mix ratios
	M567 P1 E{0,0,0}
	; Pressure advance
	M572 D0:1:2 S{var.PRESSURE_ADVANCE_FHX}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the pressure advance with infinity box" F{var.CURRENT_FILE} E17706
	M98 P"/sys/modules/fhx/emulator/handle_preload_status.g" T1
	set var.moduleFhx1 = 0.1
else
	M118 S{"no extruder available to setup with infinity box"^var.CURRENT_FILE}

; Create links
M98 P"/macros/files/link/create.g" L"/macros/fhx/power/set.g" D"/sys/modules/fhx/viio/v0/power_set.g" I{"S",}

set global.MODULE_FHX = {var.moduleFhx0, var.moduleFhx1}

M98 P"/macros/fhx/power/on.g"
M98 P"/sys/modules/fhx/emulator/handle_preload_status.g" T0
M98 P"/sys/modules/fhx/emulator/handle_preload_status.g" T1

; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit