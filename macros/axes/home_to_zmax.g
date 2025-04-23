; Description:
;	Home to Z max
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/axes/home_to_zmax.g"
M118 S{"[HOMING] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/hometozmax.g"} F{var.CURRENT_FILE} E51205

; Homing ----------------------------------------------------------------------
M98 P"/sys/hometozmax.g"

; -----------------------------------------------------------------------------
M118 S{"[HOMING] Done "^var.CURRENT_FILE}
M99