; Description: 	
;   Store a nozzle size into permanent variables
;   Input parameter : T-> 0 or 1 :tool 0 or 1  
;                     N- > nozzle size in mm
;--------------------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/save_nozzle_size.g"
M118 S{"[save.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters --------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/extruder/nozzle/save.g"} F{var.CURRENT_FILE} E84325
; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(param.T)}			Y{"Missing Tool index param T"}		F{var.CURRENT_FILE} E84326
M98 P"/macros/assert/abort_if.g"		R{(param.T == null) || !exists(tools[param.T])}	Y{"Invalid Tool index param.T %s"} A{param.T,}	F{var.CURRENT_FILE} E84327

M98 P"/macros/assert/abort_if.g"		R{!exists(param.N)}			Y{"Missing Nozzle size param.N"}	F{var.CURRENT_FILE} E84328
M98 P"/macros/assert/abort_if_null.g"	R{param.N}					Y{"Nozzle size param.N is null"}	F{var.CURRENT_FILE} E84329

; set nozzle size----------------------------------------------------------------
set global.nozzleSizes[param.T] = param.N

M98 P"/macros/extruder/nozzle/save.g" T{param.T} N{param.N}

; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;---------------------------------------------------------------------------------------------------------
M118 S{"[save.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit