
; Description: 	
;    Saves nozzle size to persistent variables
; Input Parameters:
;	- T: Tool index (only T0 supported - single extruder)
;	- N: Nozzle size in mm
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/nozzle/save.g"
M118 S{"[save.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

M98 P"/macros/assert/abort_if.g" R{!exists(param.T)}     	Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E56753
M98 P"/macros/assert/abort_if.g" R{param.T != 0} Y{"Only T0 supported - single extruder setup"} F{var.CURRENT_FILE} E56754
M98 P"/macros/assert/abort_if.g" R{!exists(param.N)} Y{"Missing Nozzle size param.N"} F{var.CURRENT_FILE} E56755
M98 P"/macros/assert/abort_if.g" R{param.N == null || param.N < 0} Y{"Invalid Nozzle size param.N %s"} A{param.N,} F{var.CURRENT_FILE} E56756

if !exists(global.nozzleSizes)
	global nozzleSizes = {0.6, 0.6}

set global.nozzleSizes[param.T] = param.N
M98 P"/macros/variable/save_number.g" N"global.nozzleSizes" V{global.nozzleSizes}
;--------------------------------------------------------------------------------------------------------
M118 S{"[save.g] Done "^var.CURRENT_FILE}
M99
