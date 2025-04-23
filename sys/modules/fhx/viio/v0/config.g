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

; Fhx box for tool 0
M98 P"/macros/boards/get_index_in_om.g" A40
var FILAMENT_BOX_0_ENABLED = (var.HAS_EXTRUDER_0 && global.boardIndexInOM != null)
; Fhx box for tool 1
M98 P"/macros/boards/get_index_in_om.g" A41
var FILAMENT_BOX_1_ENABLED = (var.HAS_EXTRUDER_1 && global.boardIndexInOM != null)
; setting the status of the FHX boxes
if (!exists(global.FHX_ENABLED))
	global FHX_ENABLED = { {var.HAS_EXTRUDER_0, var.FILAMENT_BOX_0_ENABLED}, {var.HAS_EXTRUDER_1, var.FILAMENT_BOX_1_ENABLED} }

; configuring the motors and sensor of the fhx
; Fhx box 0
if(var.FILAMENT_BOX_0_ENABLED)
	M569 P40.0 S0  ; Motor  -> S0 for turning ccw
	M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the infinity box T0 left motor" F{var.CURRENT_FILE} E17606
	M569 P40.1 S0  ; Motor  -> S0 for turning ccw
	M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the infinity box T0 right motor" F{var.CURRENT_FILE} E17680
	M400
	M98 P"/sys/modules/fhx/viio/v0/sensors.g" T0
M400
; fhx box 1
if(var.FILAMENT_BOX_1_ENABLED)
	M569 P41.0 S0  ; Motor  -> S0 for turning ccw
	M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the infinity box T1 left motor" F{var.CURRENT_FILE} E17607
	M569 P41.1 S0  ; Motor  -> S0 for turning ccw
	M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the the infinity box T1 right motor" F{var.CURRENT_FILE} E17681
	M400
	M98 P"/sys/modules/fhx/viio/v0/sensors.g" T1
M400
; drive mapping when both box exists
if (var.FILAMENT_BOX_0_ENABLED && var.FILAMENT_BOX_1_ENABLED)
	M584 E81.0:82.0:40.0:40.1:41.0:41.1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the motor-mapping infinity box T0 and infinity box T1" F{var.CURRENT_FILE} E17608
	M400
	M98 P"/sys/modules/fhx/viio/v0/drive_mapping.g"
	M400
elif (var.FILAMENT_BOX_0_ENABLED)
	if(var.HAS_EXTRUDER_1)
		M584 E82.0:81.0:40.0:40.1
	else
		M584 E81.0:40.0:40.1
	; single boxes are not supported, if mapping fails, indicate it to user
	M98  P"/macros/assert/result.g" R{result} Y"T1 Infinity Box not detected. If not installed, please unplug T1 Extruder and restart machine" F{var.CURRENT_FILE} E17609
	M400
	M98 P"/sys/modules/fhx/viio/v0/drive_mapping.g" T0
elif (var.FILAMENT_BOX_1_ENABLED)
	if(var.HAS_EXTRUDER_0 )
		M584 E81.0:82.0:41.0:41.1
	else
		M584 E82.0:41.0:41.1
	; single boxes are not supported, if mapping fails, indicate it to user
	M98  P"/macros/assert/result.g" R{result} Y"T0 Infinity Box not detected. If not installed, please unplug T0 Extruder and restart machine" F{var.CURRENT_FILE} E17651
	M98 P"/sys/modules/fhx/viio/v0/drive_mapping.g" T1
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

