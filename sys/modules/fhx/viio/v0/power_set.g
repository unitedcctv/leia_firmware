; Description:	  
;	This will control the output to power the FHX
; Input Parameters:
;	- S: 1 to turn ON , 0 to turn OFF
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/power_set.g"

M118 S{"[FHX]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_FHX)}  	Y{"Missing infinity box configuration"} F{var.CURRENT_FILE} E17670
M98 P"/macros/assert/abort_if.g" R{!exists(global.FHX_POWER_OUTPUT)}  Y{"Missing global FHX_POWER_OUTPUT"} F{var.CURRENT_FILE} E17671
M98 P"/macros/assert/abort_if.g" R{!exists(global.fhxPowerIsEnabled)}  Y{"Missing global fhxPowerIsEnabled"} F{var.CURRENT_FILE} E17672
M98 P"/macros/assert/abort_if.g" R{!exists(param.S)} 			   Y{"Missing required input parameter S"} F{var.CURRENT_FILE} E17673
M98 P"/macros/assert/abort_if_null.g" R{param.S}  	  			   Y{"Input parameter S is null"} F{var.CURRENT_FILE} E17674

var OUTPUT_VALUE = ( param.S > 0.5 ) ? 1 : 0 
if(var.OUTPUT_VALUE == global.fhxPowerIsEnabled)
	M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 1)} Y{"The infinity box power is already ON"} F{var.CURRENT_FILE} W17670
	M98 P"/macros/report/warning_if.g" R{(var.OUTPUT_VALUE == 0)} Y{"The infinity box power is already OFF"} F{var.CURRENT_FILE} W17671

M42 P{global.FHX_POWER_OUTPUT} S{var.OUTPUT_VALUE}
set global.fhxPowerIsEnabled = var.OUTPUT_VALUE

; -----------------------------------------------------------------------------
M118 S{"[FHX] Done "^var.CURRENT_FILE}
M99 ; Proper exit
