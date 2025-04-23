; Description:
;	We will scan the available boards in the object model (OM) and return
;	the index in the array "boards" of the position of a board with a CAN
;	address (param.A)
;
; Input parameters:
;	- A: Address of board we want the index
; Output parameters:
;	- global.boardIndexInOM: If the address was found, it will contain the
;			index in the array "boards". Otherwise, it will be null
; 	Example:
;		M98 P"/macros/boards/get_index_in_om.g" A81
;		M98 P"/macros/assert/abort_if_null.g" 	R{global.boardIndexInOM} Y{"Board not found"} F{var.CURRENT_FILE}
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/boards/get_index_in_om.g"
; M118 S{"[BOARD] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Cleaning the return value ---------------------------------------------------
if(!exists(global.boardIndexInOM))
	global boardIndexInOM = null
else
	set global.boardIndexInOM = null

; Checking the input parameters -----------------------------------------------
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.A)} Y{"Parameter A is missing "} F{var.CURRENT_FILE} E52000
M98 P"/macros/assert/abort_if_null.g" 	R{param.A} 			Y{"Parameter A is null"} 	 F{var.CURRENT_FILE} E52001

; Find board with address -----------------------------------------------------
while iterations < #boards
	if(exists(boards[iterations].canAddress) && boards[iterations].canAddress == param.A)
		set global.boardIndexInOM = iterations
		break

; -----------------------------------------------------------------------------
; M118 S{"[BOARD] Done "^var.CURRENT_FILE}
M99 ; Proper exit
