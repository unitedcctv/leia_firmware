; Description: 	
;	Macro used to abort if a board with certain CAN address is not present.
; Input parameters:
;	- D: Board address
;	- Y: Message to show if the board is not present.
;	- (optional) F: File name
;	- E: Integer with the error code that is being reported.
; (!) We can only call the function /macros/report/generic.g.
;---------------------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
; Checking the input paramters ------------------------------------------------
; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E01500# Missing file /macros/report/generic.g | In file /macros/assert/board_present.g"
	M118 S{global.errorMessage}	
	abort {"ABORTED in /macros/assert/board_present.g 1 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter D
if(!exists(param.D))
	M98 P"/macros/report/generic.g" S{"Missing parameter D | In file /macros/assert/board_present.g"}  E01500
	abort {"ABORTED in /macros/assert/board_present.g 2 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.D == null)
	M98 P"/macros/report/generic.g" S{"Parameter D is null | In file /macros/assert/board_present.g"}  E01501
	abort {"ABORTED in /macros/assert/board_present.g 3 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/assert/board_present.g"}  E01502
	abort {"ABORTED in /macros/assert/board_present.g 4 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/assert/board_present.g"}  E01503
	abort {"ABORTED in /macros/assert/board_present.g 5 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/assert/board_present.g"} E01504
	abort {"ABORTED in /macros/assert/board_present.g 6 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }

; Checking the conditions -----------------------------------------------------
var boardInAddr = false
while iterations < #boards
	if ( exists(boards[iterations].canAddress) && boards[iterations].canAddress == param.D )
		set var.boardInAddr = true

if( var.boardInAddr == false )
	var msg = param.Y
	if(exists(param.F) && param.F != null && param.F != "")
		set var.msg= {var.msg ^" | In file "^ param.F}

	M98 P"/macros/report/generic.g" S{var.msg} E{param.E} A{exists(param.A) ? param.A : null}

	abort {"ABORTED in /macros/assert/board_present.g 7 | " ^ {global.errorMessage}}

M99 ; Proper exit