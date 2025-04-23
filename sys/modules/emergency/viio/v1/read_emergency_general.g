; Description:
;	Read the 48V inputs from the signals.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/emergency/viio/v1/read_emergency_general.g"
M118 S{"[V48] Start "^var.CURRENT_FILE}

M98 P"/macros/assert/abort_if.g" R{!exists(global.EMERGENCY_GENERAL_INPUTS)}  Y{"Missing required global EMERGENCY_GENERAL_INPUTS"}	F{var.CURRENT_FILE} E12120

; Reading the inputs ----------------------------------------------------------
var detectIdx = 0
var triggered = true
while(var.detectIdx < #global.EMERGENCY_GENERAL_INPUTS)
	if(sensors.gpIn[global.EMERGENCY_GENERAL_INPUTS[var.detectIdx]].value != 0)
		set var.triggered = false
	set var.detectIdx = var.detectIdx + 1
set global.emergencyGeneralIsTriggered = var.triggered

; -----------------------------------------------------------------------------
M118 S{"[V48] Done "^var.CURRENT_FILE}
M99