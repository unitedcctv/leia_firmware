; Description: 	
;	Macro to log a WARNING message (W).
; Input parameters:
;	- S: Message to show with the error
;	- W: Integer with the warning code that is being reported.
; Example:
; 	M98 P"/macros/report/warning.g" Y"This is a warning" F{var.CURRENT_FILE} W12345
;------------------------------------------------------------------------------

; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E05800# Missing file /macros/report/generic.g | In file /macros/report/warning.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/warning.g"}
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/report/warning.g"} 	E05801
	abort {"ABORTED in /macros/report/warning.g"}
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/report/warning.g"} 	E05802
	abort {"ABORTED in /macros/report/warning.g"}
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/report/warning.g"} 	E05803
	abort {"ABORTED in /macros/report/warning.g"}
; Parameter W
if(!exists(param.W))
	M98 P"/macros/report/generic.g" S{"Missing parameter W | In file /macros/report/warning.g"} 	E05804
	abort {"ABORTED in /macros/report/warning.g"}
if( param.W == null)
	M98 P"/macros/report/generic.g" S{"Parameter W is null | In file /macros/report/warning.g"} 	E05805
	abort {"ABORTED in /macros/report/warning.g"}

; Create the message
var msg = param.Y
if(exists(param.F) && param.F != null && param.F != "")
	set var.msg= {var.msg ^" | In file "^ param.F}

M98 P"/macros/report/generic.g" S{var.msg} W{param.W} A{exists(param.A) ? param.A : null}

M99 ; Exit current macro