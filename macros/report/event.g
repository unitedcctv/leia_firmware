; Description: 	
;	Macro to report an EVENT message (V).
; Input parameters:
;	- S: Message to show with the error
;	- V: Integer with the event code that is being reported.
; Example:
; 	M98 P"/macros/report/event.g" Y"This is an event" F{var.CURRENT_FILE} V12345
;------------------------------------------------------------------------------

; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E05100# Missing file /macros/report/generic.g | In file /macros/report/event.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/event.g"}
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/report/event.g"} 	E05101
	abort {"ABORTED in /macros/report/event.g"}
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/report/event.g"} 	E05102
	abort {"ABORTED in /macros/report/event.g"}
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/report/event.g"} 	E05103
	abort {"ABORTED in /macros/report/event.g"}
; Parameter V
if(!exists(param.V))
	M98 P"/macros/report/generic.g" S{"Missing parameter V | In file /macros/report/event.g"} 	E05104
	abort {"ABORTED in /macros/report/event.g"}
if( param.V == null)
	M98 P"/macros/report/generic.g" S{"Parameter V is null | In file /macros/report/event.g"} 	E05105
	abort {"ABORTED in /macros/report/event.g"}

; Create the message
var msg = param.Y
if(exists(param.F) && param.F != null && param.F != "")
	set var.msg= {var.msg ^" | In file "^ param.F}

M98 P"/macros/report/generic.g" S{var.msg} V{param.V} A{exists(param.A) ? param.A : null}

M99 ; Exit current macro