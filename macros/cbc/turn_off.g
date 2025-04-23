; Description: 	
;	 Turns off the CBC.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/cbc/turn_off.g"

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/cbc/set_temperature.g"} F{var.CURRENT_FILE} E53200

; Turn off the CBC ------------------------------------------------------------
M98 P"/macros/cbc/set_temperature.g" T0

; -----------------------------------------------------------------------------
M99 ; Nothing is done