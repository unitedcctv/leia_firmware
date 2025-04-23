; Description: 	
;   This module will configure the different network settings.
; 	In this version we support HTTP (see config.g) and FTP.
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/network/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_NETWORK)}  	Y{"A previous NETWORK configuration exists"} F{var.CURRENT_FILE} E14110

; CONFIGURATION ------------------------------------------------------------------------------
M586 P1 S1					; Enable FTP
M98 P"/macros/assert/result.g" R{result} Y"Unable to enable FTP" F{var.CURRENT_FILE} E14111
M586 P2 S0				  	; Disable Telnet
M98 P"/macros/assert/result.g" R{result} Y"Unable to disable Telnet" F{var.CURRENT_FILE} E14112

M550 P"EMULATOR"			; set printer name
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the printer name" F{var.CURRENT_FILE} E14113

global MODULE_NETWORK = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit