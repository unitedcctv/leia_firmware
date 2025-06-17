; Description:
;	We control the 230V with this module.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking Files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/fhx/viio/v0/sensors.g"} F{var.CURRENT_FILE} E17600
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/fhx/viio/v0/drive_mapping.g"} F{var.CURRENT_FILE} E17601
; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_FHX)}  	 Y{"A previous infinity box configuration exists"} 	F{var.CURRENT_FILE} E17602
M98 P"/macros/assert/abort_if.g" R{!exists(boards[0].canPorts)}  Y{"Missing canPorts in the OM"} 			F{var.CURRENT_FILE} E17603
M98 P"/macros/assert/abort_if.g" R{(boards[0].canPorts < 2)}  	 Y{"Not enough CAN-FD ports available"} 	F{var.CURRENT_FILE} E17604

; DEFINITIONS --------------------------------------------------------------------------------
var FHX_POWER_PORT = "0.fan0"		; variable to store the Pin id of the FHX power controller
M98 P"/macros/get_id/output.g"
global FHX_POWER_OUTPUT = global.outputId	; variable to store the output id of the FHX power controller

global fhxPowerIsEnabled = 0  ; Variable to store the current status of the FHX-Power:
							  ;	 0 : It is OFF
							  ;	 1 : It is ON

; CONFIGURATION ---------------------------------------------------------------
; Power output
M950 P{global.FHX_POWER_OUTPUT} C{var.FHX_POWER_PORT} Q1
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the infinity box power output"  F{var.CURRENT_FILE} E17605

; Checking if there are extruders 
var HAS_EXTRUDER_0 = (exists(global.MODULE_EXTRUDER_0) && global.MODULE_EXTRUDER_0 > 0)
var HAS_EXTRUDER_1 = (exists(global.MODULE_EXTRUDER_1) && global.MODULE_EXTRUDER_1 > 0)

; creating variables
if(!exists(global.boardIndexInOM))
	global boardIndexInOM = null

M400
; Create links
M98 P"/macros/files/link/create.g" L"/macros/fhx/power/set.g" D"/sys/modules/fhx/viio/v0/power_set.g" I{"S",}
; set the module version
var moduleFhx0 = null
var moduleFhx1 = null
if (var.FILAMENT_BOX_0_ENABLED)
	set var.moduleFhx0 = 0.1
if (var.FILAMENT_BOX_1_ENABLED)
	set var.moduleFhx1 = 0.1
M400
global MODULE_FHX = {var.moduleFhx0, var.moduleFhx1}

; Setting the lights in the default status
if(var.FILAMENT_BOX_0_ENABLED || var.FILAMENT_BOX_1_ENABLED)
	M98 P"/macros/fhx/power/on.g"
	M98 P"/macros/files/daemon/add.g" F"/sys/modules/fhx/viio/v0/daemon.g"	; add deamon
else
	M98 P"/macros/fhx/power/off.g"
M400
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit

