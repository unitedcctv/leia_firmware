; Description: 	
;	We will automatically detect the extruders in the machine based on their
;	inputs or the type of machine. The emulator only supports emulated 
;	extruders, while in the rest of the machines the expansion board should be
;	used to detect the type.
; Input Parameters:
;	- T: Tool 0 or 1 to configure
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/automatic_detection.g"
M118 S{"[TOOL] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}  			Y{"Missing required input parameter T"} F{var.CURRENT_FILE} E57000
M98 P"/macros/assert/abort_if_null.g" R{param.T}  	  			Y{"Input parameter T is null"} 			F{var.CURRENT_FILE} E57001	
M98 P"/macros/assert/abort_if.g" R{(param.T>=2||param.T<0)}  	Y{"Unexpected tool value"} 				F{var.CURRENT_FILE} E57002	
M98 P"/macros/assert/abort_if.g" R{(param.T == 0) && exists(global.MODULE_EXTRUDER_0)}  Y{"A previous EXTRUDER_0 configuration exists"} F{var.CURRENT_FILE} E57003
M98 P"/macros/assert/abort_if.g" R{(param.T == 1) && exists(global.MODULE_EXTRUDER_1)}  Y{"A previous EXTRUDER_1 configuration exists"} F{var.CURRENT_FILE} E57004

; Creation of emulated extruder -----------------------------------------------
if network.hostname == "emulator"	
	M98 P"/sys/modules/extruders/emulator/v0/config.g" T{param.T}
	M99 ; Proper exit

; Board detection -------------------------------------------------------------
var BOARD_ADDRESS = {83 + param.T}
M98 P"/macros/boards/get_index_in_om.g" A{var.BOARD_ADDRESS}
if( global.boardIndexInOM == null )
	M118 S{"[TOOL] No board connected to T"^param.T}
	M99 ; Proper exit

; Create an input to see the type of extruder ---------------------------------
; TODO: Remove this! if it is needed, the input should be in the module!
M98 P"/macros/get_id/input.g"
var DETECT_INPUT = global.inputId
M950 J{var.DETECT_INPUT} C{ var.BOARD_ADDRESS^".io1.in"}
; Small wait
G4 S0.3

; Intialize the proper extruder based on its input ----------------------------
; Reading the input value.
if (sensors.gpIn[var.DETECT_INPUT].value == 0)
	M98 P"/sys/modules/extruders/lgx/v0/config.g" T{param.T}
else
	M98 P"/sys/modules/extruders/qr/v2/config.g" T{param.T}

; -----------------------------------------------------------------------------
M118 S{"[TOOL] Done "^var.CURRENT_FILE}
M99 ; Proper exit