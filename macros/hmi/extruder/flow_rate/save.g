; Description: 	
;   This is a HMI command macro to save the flowrate value to the global variable flowRateMultipliers
;       - this macro is used to call the flowrate save.g from the macros
;   Input parameter : T-> 0 or 1 :tool 0 or 1  
;                     K- > the value of the flow rate multiplier of the tool in percentage
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/flow_rate/save.g"
M118 S{"[save.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/flow_rate/save.g"} F{var.CURRENT_FILE} E84310
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/flow_rate/load.g"} F{var.CURRENT_FILE} E84321
; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(param.T)}     	Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E84315
M98 P"/macros/assert/abort_if_null.g" 	R{param.T}              	Y{"Tool index param.T is null"} 	F{var.CURRENT_FILE} E84316

M98 P"/macros/assert/abort_if.g"		R{!exists(param.K)}     	Y{"Missing the flow rate multiplier"}    	F{var.CURRENT_FILE} E84318
M98 P"/macros/assert/abort_if_null.g" 	R{param.K}              	Y{"The flow rate multiplier is null"} 	F{var.CURRENT_FILE} E84319

; set flow rate----------------------------------------------------------------
M98 P"/macros/extruder/flow_rate/save.g" T{param.T} K{param.K}
M598
M98 P"/macros/extruder/flow_rate/load.g" T{param.T}
M400

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------------------
M118 S{"[save.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit