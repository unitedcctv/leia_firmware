; Description: 	
;	Macro used to abort if the condition if true
; Input parameters:
;	- R: Path to file
;	- (optional) F: File name
;	- E: Integer with the error code that is being reported.
;------------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99
;------------------------------------------------------------------------------
; Checking the input paramters ------------------------------------------------
; Macros
if(!fileexists("/macros/report/generic.g"))
	set global.errorMessage = "#E01300# Missing file /macros/report/generic.g | In file /macros/assert/abort_if_file_missing.g"
	M118 S{global.errorMessage}	
	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 1 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter R
if(!exists(param.R))
	M98 P"/macros/report/generic.g" S{"Missing parameter R | In file /macros/assert/abort_if_file_missing.g"} 	E01300
	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 2 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.R == null)
	M98 P"/macros/report/generic.g" S{"Parameter R is null | In file /macros/assert/abort_if_file_missing.g"} 	E01301
	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 3 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
; Parameter E
if(!exists(param.E))
	M98 P"/macros/report/generic.g" S{"Missing parameter E | In file /macros/assert/abort_if_file_missing.g"} 	E01302
	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 4 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }
if( param.E == null)
	M98 P"/macros/report/generic.g" S{"Parameter E is null | In file /macros/assert/abort_if_file_missing.g"} 	E01303
	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 5 | " ^ { (exists(param.F) && param.F != null) ? param.F : ""} }

; Checking the conditions -----------------------------------------------------
if(!fileexists(param.R))
	var msg = {"Missing required file " ^ param.R}
	if(exists(param.F) && param.F != null && param.F != "")
		set var.msg= {var.msg ^" | In file "^ param.F}

	M98 P"/macros/report/generic.g" S{var.msg} E{param.E} A{exists(param.A) ? param.A : null}

	abort {"ABORTED in /macros/assert/abort_if_file_missing.g 6 | " ^ { global.errorMessage }}
M99 ; Exit current macro