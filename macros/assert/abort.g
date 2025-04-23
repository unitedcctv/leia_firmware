; Description: 	
;	Macro used to abort with a messsage and error
; Input parameters:
;	- Y: Message to show before abort if the variable is false.
;	- (optional) F: File name
;	- E: Integer with the error code that is being reported.
; (!) We can only call the function /macros/report/generic.g.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E00010# Missing file /macros/report/generic.g | In file /macros/assert/abort.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/assert/abort.g 1 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/assert/abort.g"} 	E01100
	abort {"ABORTED in /macros/assert/abort.g 2 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/assert/abort.g"} 	E01101
	abort {"ABORTED in /macros/assert/abort.g 3 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/assert/abort.g"} 	E01102
	abort {"ABORTED in /macros/assert/abort.g 4 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter E
if(!exists(param.E))
	M98 P"/macros/report/generic.g" S{"Missing parameter E | In file /macros/assert/abort.g"} 	E01103
	abort {"ABORTED in /macros/assert/abort.g 5 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.E == null)
	M98 P"/macros/report/generic.g" S{"Parameter E is null | In file /macros/assert/abort.g"} 	E01104
	abort {"ABORTED in /macros/assert/abort.g 6 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }

; Checking the conditions -----------------------------------------------------
var msg = param.Y
if(exists(param.F) && param.F != null && param.F != "")
	set var.msg= {var.msg ^" | In file "^ param.F}

M98 P"/macros/report/generic.g" S{var.msg} E{param.E} A{exists(param.A) ? param.A : null}

abort {"ABORTED in /macros/assert/abort.g 7 | " ^ {global.errorMessage}}

M99