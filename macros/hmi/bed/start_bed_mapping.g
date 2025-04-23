; Description: 	
;	Macro to start bed mapping
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/bed/start_bed_mapping.g"
M118 S{"[start_bed_mapping.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
M98 P"/macros/doors/lock.g"
M400

; Homing ----------------------------------------------------------------------
; Deselecting the current tool
T-1
M400

M118 S"[start_bed_mapping.g] Homing all first"
G28
M400

set global.jobBBOX = null ; clear the job bounding box
; run bed mapping
G32
M400
M98 P"/macros/doors/unlock.g"
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
; -----------------------------------------------------------------------------
M118 S{"[start_bed_mapping.g] Done "^var.CURRENT_FILE}
M99