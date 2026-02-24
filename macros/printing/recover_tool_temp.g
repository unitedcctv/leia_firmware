; Description: 	
;	This macro is used to recover the temperature saved in global.lastPrintingTemps 
;	variable to the active tool.
;	--------------------------------------------------------------
var CURRENT_FILE = "/macros/printing/recover_tool_temp.g"
M118 S{"[recover_tool_temp.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Definitions--------------------------------------------------------------------
M98 P"/macros/assert/abort_if.g" R{!exists(global.lastPrintingTemps)} Y{"Missing global.lastPrintingTemps"} F{var.CURRENT_FILE} E64006

if(exists(tools[0]) && (global.lastPrintingTemps[0]!= null))
	M568 P0 S{global.lastPrintingTemps[0]} R{global.lastPrintingTemps[0]} A2	
M118 S{"setting T0 to "^global.lastPrintingTemps[0]}
;--------------------------------------------------------------------------------
M118 S{"[recover_tool_temp.g] Done "^var.CURRENT_FILE}
M99 ;Proper exit
