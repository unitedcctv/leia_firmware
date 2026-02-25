; Description:
;	This file is automatically when there is a driver warning.
;	File required by Duet3D.
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/driver-warning.g"
M118 S{"[DRIVER] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Definitions -----------------------------------------------------------------
var canAddress = { exists(param.B) ? {""^param.B} : "UNKNOWN"}
var message = ""

; Disable the motors
M18
;-----------------------------------------------------------------------------
set global.errorRestartRequired = true
;CAN address look up table
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
; Param.P look up table-------------------------------------------------------
if(exists(param.P))
	var driverStatusWord = param.P	; We need to translate the status word to decode the error/warning state
	M118 S{"Driver warning with a status bit "^param.P}
	if(var.driverStatusWord >= 256)
		set var.message = " Standstill indicator."
		set var.driverStatusWord = var.driverStatusWord - 256
	if(var.driverStatusWord >= 128)
		set var.message = var.message^" Phase B may be disconnected."
		set var.driverStatusWord = var.driverStatusWord - 128
	if(var.driverStatusWord >= 64)
		set var.message = var.message^" Phase A may be disconnected."
		set var.driverStatusWord = var.driverStatusWord - 64
	if(var.driverStatusWord >= 32)
		set var.message = var.message^" Phase B short to Vin."
		set var.driverStatusWord = var.driverStatusWord - 32
	if(var.driverStatusWord >= 16)
		set var.message = var.message^" Phase A short to Vin."
		set var.driverStatusWord = var.driverStatusWord - 16
	if(var.driverStatusWord >= 8)
		set var.message = var.message^" Phase B short to ground."
		set var.driverStatusWord = var.driverStatusWord - 8
	if(var.driverStatusWord >= 4)
		set var.message = var.message^" Phase A short to ground."
		set var.driverStatusWord = var.driverStatusWord - 4
	if(var.driverStatusWord >= 2)
		set var.message = var.message^" Over temperature warning."
		set var.driverStatusWord = var.driverStatusWord - 2
	if(var.driverStatusWord >= 1)
		set var.message = var.message^" Overtemperature shutdown."
		set var.driverStatusWord = var.driverStatusWord - 1
	set var.message  = {"Warning in motor driver "^param.D^" of "^var.canAddress^" board indicates "^var.message}
else
	set var.message  = {"Warning in driver "^param.D^" of "^var.canAddress^" board without status bits"}
; report the error------------------------------------------------------------
M98 P"/macros/assert/abort.g" Y{var.message^" Please restart the machine"}  F{var.CURRENT_FILE} E31202
; -----------------------------------------------------------------------------
M118 S{"[driver-warning.g] Done "^var.CURRENT_FILE}
M99