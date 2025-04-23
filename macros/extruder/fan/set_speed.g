; Description: 	
;	This macro is used to set the speed of the specified fan
;   the value should be in the range 0 to 1
; Input Parameters:
;	- T: Tool 0 or 1 to set the flowrate
;	- S: Speed in 0.0 to 1.0
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/extruder/fan/set_speed.g"
M118 S{"[FAN] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(global.toolFanId)}    Y{"Missing the global variable to store the fan id"}    	F{var.CURRENT_FILE} E57665

M98 P"/macros/assert/abort_if.g"		R{!exists(param.T)}     		Y{"Missing Tool index param T"}    	F{var.CURRENT_FILE} E57660
M98 P"/macros/assert/abort_if_null.g" 	R{param.T}              		Y{"Tool index param.T is null"} 	F{var.CURRENT_FILE} E57661
M98 P"/macros/assert/abort_if.g" 		R{(!exists(tools[param.T]))} 	Y{"Tool param T= %s outside range of available tools %s"} A{param.T, #tools}    F{var.CURRENT_FILE} E57662
M98 P"/macros/assert/abort_if.g"		R{!exists(param.S)}     		Y{"Missing the speed param S"}    	F{var.CURRENT_FILE} E57666
M98 P"/macros/assert/abort_if_null.g" 	R{param.S}              		Y{"Fan speed param S is null"} 		F{var.CURRENT_FILE} E57663
M98 P"/macros/assert/abort_if.g" 		R{param.S < 0|| param.S >1}		Y{"Entered fan speed  is out of range (0 to 1)"} F{var.CURRENT_FILE} E57664
; Setting the tool fan speed
if ((param.T == 0) && (global.toolFanId[0]!= null))
	M106 P{global.toolFanId[0]} S{param.S}
	M118 S{"[FAN] Set the tool 0 fan to the pwm value"^ param.S}
if ((param.T == 1) && (global.toolFanId[1]!= null))
	M106 P{global.toolFanId[1]} S{param.S}
	M118 S{"[FAN] Set the tool 1 fan to the pwm value"^ param.S}
; -----------------------------------------------------------------------------
M118 S{"[FAN] Done "^var.CURRENT_FILE}
M99 ; Proper exit