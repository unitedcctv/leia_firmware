
; Description: 	
;    Saves the flow rates stored in global.flowRateMultipliers to persistent variables
; Input Parameters:
;	- T: Tool index (only T0 supported - single extruder)
;	- K: Flow rate multiplier in percentage
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/flow_rate/save.g"
M118 S{"[save.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}     	Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E56743
M98 P"/macros/assert/abort_if.g" R{param.T != 0} Y{"Only T0 supported - single extruder setup"} F{var.CURRENT_FILE} E56744
M98 P"/macros/assert/abort_if.g" R{!exists(param.K)} Y{"Missing flow rate multiplier param K"} F{var.CURRENT_FILE} E56745
M98 P"/macros/assert/abort_if.g" R{param.K < 1 || param.K > 200} Y{"Invalid flow rate multiplier: "} A{param.K,} F{var.CURRENT_FILE} E56746

if !exists(global.flowRateMultipliers)
	global flowRateMultipliers = {100}

set global.flowRateMultipliers[param.T] = param.K
M98 P"/macros/variable/save_number.g" N"global.flowRateMultipliers" V{global.flowRateMultipliers}
;--------------------------------------------------------------------------------------------------------
M118 S{"[save.g] Done "^var.CURRENT_FILE}
M99
