; Description: 	
;	Macro used to abort if the condition if true
; Input parameters:
;	- R: Use to evaluate if it is true or not.
;	- Y: Message to show before abort if the variable is false.
;	- (optional) F: File name
;	- E: Integer with the error code that is being reported.
; (!) We can only call the function /macros/report/generic.g.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
; Checking the input paramters ------------------------------------------------
; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E01200# Missing file /macros/report/generic.g | In file /macros/assert/abort_if.g"
	M118 S{global.errorMessage}	
	abort {"ABORTED in /macros/assert/abort_if.g 1 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter R
if(!exists(param.R))
	M98 P"/macros/report/generic.g" S{"Missing parameter R | In file /macros/assert/abort_if.g"} 	E01200
	abort {"ABORTED in /macros/assert/abort_if.g 2 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.R == null)
	M98 P"/macros/report/generic.g" S{"Parameter R is null | In file /macros/assert/abort_if.g"} 	E01201
	abort {"ABORTED in /macros/assert/abort_if.g 3 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/assert/abort_if.g"} 	E01202
	abort {"ABORTED in /macros/assert/abort_if.g 4 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/assert/abort_if.g"} 	E01203
	abort {"ABORTED in /macros/assert/abort_if.g 5 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/assert/abort_if.g"} 	E01204
	abort {"ABORTED in /macros/assert/abort_if.g 6 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter E
if(!exists(param.E))
	M98 P"/macros/report/generic.g" S{"Missing parameter E | In file /macros/assert/abort_if.g"} 	E01205
	abort {"ABORTED in /macros/assert/abort_if.g 7 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.E == null)
	M98 P"/macros/report/generic.g" S{"Parameter E is null | In file /macros/assert/abort_if.g"} 	E01206
	abort {"ABORTED in /macros/assert/abort_if.g 8 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }

; Checking the conditions -----------------------------------------------------
if(param.R == true)
	var msg = param.Y
	if(exists(param.F) && param.F != null && param.F != "")
		set var.msg= {var.msg ^" | In file "^ param.F}

	M98 P"/macros/report/generic.g" S{var.msg} E{param.E} A{exists(param.A) ? param.A : null}

	abort {"ABORTED in /macros/assert/abort_if.g 9 | " ^ {global.errorMessage}}

M99 ; Exit current macro