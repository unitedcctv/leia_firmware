; Description: 	
;	Macro to log a WARNING message (W).
; Input parameters:
;	- R: Use to evaluate if it is true or not.
;	- S: Message to show with the error
;	- W: Integer with the warning code that is being reported.
; Example:
; 	M98 P"/macros/report/warning_if.g" R{var.NOT_HOMED} Y"You should home" F{var.CURRENT_FILE} W12345
;------------------------------------------------------------------------------

; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E05900# Missing file /macros/report/generic.g | In file /macros/report/warning_if.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/warning_if.g"}
; Parameter R
if(!exists(param.R))
	M98 P"/macros/report/generic.g" S{"Missing parameter R | In file /macros/report/warning_if.g"} 	E05901
	abort {"ABORTED in /macros/report/warning_if.g"}
if( param.R == null)
	M98 P"/macros/report/generic.g" S{"Parameter R is null | In file /macros/report/warning_if.g"} 	E05902
	abort {"ABORTED in /macros/report/warning_if.g"}
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/report/warning_if.g"} 	E05903
	abort {"ABORTED in /macros/report/warning_if.g"}
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/report/warning_if.g"} 	E05904
	abort {"ABORTED in /macros/report/warning_if.g"}
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/report/warning_if.g"} E05905
	abort {"ABORTED in /macros/report/warning_if.g"}
; Parameter W
if(!exists(param.W))
	M98 P"/macros/report/generic.g" S{"Missing parameter W | In file /macros/report/warning_if.g"} 	E05906
	abort {"ABORTED in /macros/report/warning_if.g"}
if( param.W == null)
	M98 P"/macros/report/generic.g" S{"Parameter W is null | In file /macros/report/warning_if.g"} 	E05907
	abort {"ABORTED in /macros/report/warning_if.g"}

; Create the message
if(param.R == true)
	var msg = param.Y
	if(exists(param.F) && param.F != null && param.F != "")
		set var.msg= {var.msg ^" | In file "^ param.F}

	M98 P"/macros/report/generic.g" S{var.msg} W{param.W} A{exists(param.A) ? param.A : null}
M99 ; Exit current macro