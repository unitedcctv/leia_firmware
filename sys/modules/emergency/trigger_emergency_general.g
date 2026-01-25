; Description:
; 		 Turn everything off
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/trigger_emergency_general.g"
M118 S{"[V48] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/modules/emergency/read_emergency_general.g"} F{var.CURRENT_FILE} E12140
; Checking globals
M98 P"/macros/assert/abort_if.g" R{!exists(global.emergencyGeneralIsTriggered)}  Y{"Missing required global emergencyGeneralIsTriggered"}	F{var.CURRENT_FILE} E12141
; Reading the 48V input -------------------------------------------------------
M98 P"/sys/modules/emergency/read_emergency_general.g"

; Restarting if the 48V emergency was triggered -------------------------------
if(global.emergencyGeneralIsTriggered)
	set global.hmiStateDetail = "error_emergency_general"
	set global.errorRestartRequired = true
	M98 P"/macros/report/warning.g" Y"Emergency Stop Triggered. Release E-STOP and restart machine" F{var.CURRENT_FILE} W12142
	M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
	M112 ; M112 reacts way faster than M999

; -----------------------------------------------------------------------------
M99