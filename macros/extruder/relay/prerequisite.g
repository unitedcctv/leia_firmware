; Description: 	
;	This macro checks whether the prerequisites of activate the extruder relay is set or not
;		- Both tools exists and is loaded with the material
;		- HMI will make sure that both are loaded with the same material
;
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/relay/prerequisite.g"
M118 S{"[EXTRUDER_RELAY] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; checking the global parameters
if(!exists(global.activateExtruderRelay))
	global activateExtruderRelay = false
M598

; Definitions
var MODULE_EXISTS  = (exists(global.MODULE_EXTRUDER_0) && exists(global.MODULE_EXTRUDER_1))
if (network.hostname == "emulator")
	if(var.MODULE_EXISTS)
		set global.activateExtruderRelay = true
	else
		M98 P"/macros/report/warning.g"  Y{"Needs two extruder to activate the extruder relay"}    F{var.CURRENT_FILE} W57632
	M118 S{"[EXTRUDER_RELAY] Done "^var.CURRENT_FILE}
	M99

; Definitions
var NO_FILAMENT_T0 = (exists(global.OOF_INPUTS_ID) && (sensors.gpIn[global.OOF_INPUTS_ID[0]].value == 0)) ? true : false
var NO_FILAMENT_T1 = (exists(global.OOF_INPUTS_ID) &&(sensors.gpIn[global.OOF_INPUTS_ID[1]].value == 0)) ? true : false
; Activate the extruder relay if it is an emulator board ---------------------------------------------

; Checking the prerequisite conditions ---------------------------------------------------------------
if((!var.MODULE_EXISTS) && (!global.activateExtruderRelay))
	M98 P"/macros/report/warning.g"  Y{"Needs two extruder to activate the extruder relay"}    F{var.CURRENT_FILE} W57626
if(var.NO_FILAMENT_T0)
	M98 P"/macros/report/warning.g"  Y{"No filament in extruder 0: Can't activate the extruder relay"}    F{var.CURRENT_FILE} W57627
if(var.NO_FILAMENT_T1)
	M98 P"/macros/report/warning.g"  Y{"No filament in extruder 1: Can't activate the extruder relay"}    F{var.CURRENT_FILE} W57628

; Activating the ectruder relay
if((var.MODULE_EXISTS) && (!var.NO_FILAMENT_T0) && (!var.NO_FILAMENT_T1) && !global.activateExtruderRelay)
	set global.activateExtruderRelay = true
	M98 P"/macros/report/warning.g" Y{"Extruder relay is activated for this print"} F{var.CURRENT_FILE} W57630
elif(global.activateExtruderRelay && ((var.NO_FILAMENT_T0)||(var.NO_FILAMENT_T1)||(!var.MODULE_EXISTS)))
	M98 P"/macros/report/warning.g" Y{"Prerequisites are not met: Cannot activate the extruder relay"} F{var.CURRENT_FILE} W57631
;--------------------------------------------------------------------------------------------------------
M118 S{"[EXTRUDER_RELAY] Done "^var.CURRENT_FILE}
M99
