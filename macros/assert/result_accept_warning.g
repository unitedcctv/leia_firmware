; Description: 	
;	Macro used to check the if the default "result" that is returned by G-Codes
; 	and M-Codes is reporting an error and abort in that case.
;	If the result is a warning, no abort will be called.
; Input parameters:
;	- R: (!) The variable 'result' needs to be passed here!
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
	set global.errorMessage = "#E01700# Missing file /macros/report/generic.g | In file /macros/assert/result_accept_warning.g"
	M118 S{global.errorMessage}	
	abort {"ABORTED in /macros/assert/result_accept_warning.g 1 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter R
if(!exists(param.R))
	M98 P"/macros/report/generic.g" S{"Missing parameter R | In file /macros/assert/result_accept_warning.g"} 	E01701
	abort {"ABORTED in /macros/assert/result_accept_warning.g 2 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.R == null)
	M98 P"/macros/report/generic.g" S{"Parameter R is null | In file /macros/assert/result_accept_warning.g"} 	E01702
	abort {"ABORTED in /macros/assert/result_accept_warning.g 3 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter Y
if(!exists(param.Y))
	M98 P"/macros/report/generic.g" S{"Missing parameter Y | In file /macros/assert/result_accept_warning.g"} 	E01703
	abort {"ABORTED in /macros/assert/result_accept_warning.g 4 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == null)
	M98 P"/macros/report/generic.g" S{"Parameter Y is null | In file /macros/assert/result_accept_warning.g"} 	E01704
	abort {"ABORTED in /macros/assert/result_accept_warning.g 5 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.Y == "" )
	M98 P"/macros/report/generic.g" S{"Parameter Y is empty | In file /macros/assert/result_accept_warning.g"} 	E01705
	abort {"ABORTED in /macros/assert/result_accept_warning.g 6 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter E
if(!exists(param.E))
	M98 P"/macros/report/generic.g" S{"Missing parameter E | In file /macros/assert/result_accept_warning.g"} 	E01706
	abort {"ABORTED in /macros/assert/result_accept_warning.g 7 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.E == null)
	M98 P"/macros/report/generic.g" S{"Parameter E is null | In file /macros/assert/result_accept_warning.g"} 	E01707
	abort {"ABORTED in /macros/assert/result_accept_warning.g 8 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }

; Checking the conditions -----------------------------------------------------
if( param.R==2 )
	; Create the message
	var msg = param.Y
	if(exists(param.F) && param.F != null && param.F != "")
		set var.msg= {var.msg ^" | In file "^ param.F}

	M98 P"/macros/report/generic.g" S{var.msg} E{param.E} A{exists(param.A) ? param.A : null}

	abort {"ABORTED in /macros/assert/result_accept_warning.g 9 | " ^ {global.errorMessage}}
M99 ; Exit current macro