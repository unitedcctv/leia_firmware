; Description: 	
;	Macro to report a message that is an ERROR (E), WARNING (W), EVENT (V) or
;	LOG (L). At least one and only one of the parameters E, W, V or L must be 
;	used.
;	(!) NOTE: Don't use it in non safe macros. So it is reserved for:
;		+ /macros/assert
;		+ /macros/report
; Input parameters:
;	- S: Message to show with the error
;	- (optional) E: Integer with the error code that is being reported.
;	- (optional) W: Integer with the warning code that is being reported.
;	- (optional) V: Integer with the event code that is being reported.
;	- (optional) L: Integer with the log code that is being reported.
;	- (optional) A: Parameter array with the numbers to be  reported.
;------------------------------------------------------------------------------

if(!exists(param.S) || (exists(param.S) && param.S == null))
	set global.errorMessage = "#E05001# Missing parameter S | In file /macros/report/generic.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/generic.g"}

var counterParameters = 0
var report = ""
var reportMessage = ""
if(exists(param.E) && param.E != null && param.E >= 0 && param.E < 100000)
	set var.report = "#E"
	if(param.E >= 10000)
		set var.report = {var.report^param.E}
	elif(param.E >= 1000)
		set var.report = {var.report^"0"^param.E}
	elif(param.E >= 100)
		set var.report = {var.report^"00"^param.E}
	elif(param.E >= 10)
		set var.report = {var.report^"000"^param.E}
	else
		set var.report = {var.report^"0000"^param.E}
	set var.counterParameters = var.counterParameters + 1 
if(exists(param.W) && param.W != null && param.W >= 0 && param.W < 100000)
	set var.report = "#W"
	if(param.W >= 10000)
		set var.report = {var.report^param.W}
	elif(param.W >= 1000)
		set var.report = {var.report^"0"^param.W}
	elif(param.W >= 100)
		set var.report = {var.report^"00"^param.W}
	elif(param.W >= 10)
		set var.report = {var.report^"000"^param.W}
	else
		set var.report = {var.report^"0000"^param.W}
	set var.counterParameters = var.counterParameters + 1 
if(exists(param.V) && param.V != null && param.V >= 0 && param.V < 100000)
	set var.report = "#V"
	if(param.V >= 10000)
		set var.report = {var.report^param.V}
	elif(param.V >= 1000)
		set var.report = {var.report^"0"^param.V}
	elif(param.V >= 100)
		set var.report = {var.report^"00"^param.V}
	elif(param.V >= 10)
		set var.report = {var.report^"000"^param.V}
	else
		set var.report = {var.report^"0000"^param.V}
	set var.counterParameters = var.counterParameters + 1 
if(exists(param.L) && param.L != null && param.L >= 0 && param.L < 100000)
	set var.report = "#L"
	if(param.L >= 10000)
		set var.report = {var.report^param.L}
	elif(param.L >= 1000)
		set var.report = {var.report^"0"^param.L}
	elif(param.L >= 100)
		set var.report = {var.report^"00"^param.L}
	elif(param.L >= 10)
		set var.report = {var.report^"000"^param.L}
	else
		set var.report = {var.report^"0000"^param.L}
	set var.counterParameters = var.counterParameters + 1 

if(var.counterParameters == 0)
	set global.errorMessage = "#E05002# Missing parameter E, W, V or L while calling | In file /macros/report/generic.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/generic.g"}
if(var.counterParameters > 1)
	set global.errorMessage = "#E05003# Only parameter E, W, V or L is supported | In file /macros/report/generic.g"
	M118 S{global.errorMessage}
	abort {"ABORTED in /macros/report/generic.g"}

; Reporting the message
set var.reportMessage = {var.report^"# "^param.S}
if (exists(param.A) && param.A != null)
	set var.reportMessage = {var.reportMessage^" | "^param.A}

if(exists(param.E))
	set global.errorMessage = var.reportMessage

M118 S{var.reportMessage}
M99 ; Exit current macro