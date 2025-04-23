; Description: 	
;	   To run diagnostic for all the boards.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/printing/log_diagnostics.g"
M118 S{"[log_diagnostics.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; run M122 for all the existing boards
while iterations < #boards
	var board = exists(boards[iterations].canAddress) ? boards[iterations].canAddress : 0
	M118 S{"Running M122 B"^var.board}
	M122 B{var.board}
	G4 S0.1
; -----------------------------------------------------------------------------
M118 S{"[log_diagnostics.g] Done "^var.CURRENT_FILE}
M99