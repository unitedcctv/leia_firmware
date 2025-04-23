; Description:
;	Macro to be run one time right after installing the gearboxes kit.
;   This macro creates a flag file to be checked at startup to load the proper axes configuration.
;
;   1) Install gearboxes and restart the machine
;   2) Run this macro before doing anything else
;   3) Restart machine
;   4) Move stage to the far right
;   5) Home
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/axes/set_gearbox_config.g"
M118 S{"[set_gearbox_config.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Create the flag file saving installation time
echo >"/sys/modules/axes/viio/v2/_gearboxes_installed.txt" state.time
; Block homing for safety
set global.errorRestartRequired = true

; -----------------------------------------------------------------------------
M118 S{"[set_gearbox_config.g] Done "^var.CURRENT_FILE^". PLEASE RESTART THE MACHINE."}
M99
