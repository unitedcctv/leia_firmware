; Description:
;	The printer light switch if no param T both lights are switched together.
; Example:
;	M98 P"/macros/hmi/lights/switch.g" L0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/lights/switch.g"
M118 S{"[LIGHTS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Controlling the lights ------------------------------------------------------
if(exists(param.T))
    M98 P"/macros/lights/set.g" L{param.L} T{param.T}
else
    M98 P"/macros/lights/set.g" L{param.L}

; Checking the Call Id param for HMI
if exists(param.I)
    M118 S{"#I"^param.I^"#DONE"}

; -----------------------------------------------------------------------------
M118 S{"[LIGHTS] Done "^var.CURRENT_FILE}
M99 ; Proper exit