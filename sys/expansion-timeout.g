; Description:
;	This file is automatically execute when there is a timeout in the CAN communication.
;	File required by Duet3D. 
;	Param B: the CAN address of the board whose connection got timed out
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/expansion-timeout.g"
M118 S{"[DRIVER] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Definitions------------------------------------------------------------------
var canAddress = { exists(param.B) ? {""^param.B} : "UNKNOWN"}
var message = ""
; CAN Address look up table----------------------------------------
if(var.canAddress == "0") 
	set var.canAddress = "Main"
elif(var.canAddress == "10")
	set var.canAddress = "X motor"
elif(var.canAddress == "25")
	set var.canAddress = "Y motor"
elif(var.canAddress == "30")
	set var.canAddress = "left Z motor"
elif(var.canAddress == "31")
	set var.canAddress = "Right Z motor"
elif(var.canAddress == "70")
	set var.canAddress = "Stage"
elif(var.canAddress == "20")
	set var.canAddress = "T0"
elif(var.canAddress == "21")
	set var.canAddress = "Unknown"
; report the error------------------------------------------------------------
M98 P"/macros/report/event.g" Y{"CAN connection timeout in %s board. Please check the CAN connection and restart the machine"} A{var.canAddress,}  F{var.CURRENT_FILE} V31401
if state.status == "processing"
	M999 ; restart all the boards if it happens while printing
; -----------------------------------------------------------------------------
M99
