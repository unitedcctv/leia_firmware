; Description: 	
;   This module will configure the different network settings.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/network/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_NETWORK)}  	Y{"A previous NETWORK configuration exists"} F{var.CURRENT_FILE} E14100

; CONFIGURATION ------------------------------------------------------------------------------
M586 P2 S0				  	; Disable Telnet
M98 P"/macros/assert/result.g" R{result} Y"Unable to disable Telnet" F{var.CURRENT_FILE} E14102

global MODULE_NETWORK = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit