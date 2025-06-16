; Description:
;	This file is automatically when there is a heater fault.
;	File required by Duet3D. 
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/sys/heater-fault.g"
M118 S{"[HEATER] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "error_heater"
; Reporting the error ---------------------------------------------------------
var HEATER_ID = { exists(param.D) ? {""^param.D} : "UNKNOWN"}
var HEATER_ERROR_ID = { exists(param.P) ? {""^param.D} : "UNKNOWN"}
var ERROR_MESSAGE = { exists(param.S) ? {""^param.S} : "UNKNOWN"}
var CAN_ADDRESS = { exists(param.B) ? {""^param.B} : "UNKNOWN"}

if(var.CAN_ADDRESS == "0")
	set var.CAN_ADDRESS = "Main"
elif(var.CAN_ADDRESS == "10")
	set var.CAN_ADDRESS = "X motor"
elif(var.CAN_ADDRESS == "25")
	set var.CAN_ADDRESS = "Y motor"
elif(var.CAN_ADDRESS == "30")
	set var.CAN_ADDRESS = "left Z motor"
elif(var.CAN_ADDRESS == "31")
	set var.CAN_ADDRESS = "Right Z motor"
elif(var.CAN_ADDRESS == "20")
	set var.CAN_ADDRESS = "T0"

M400

var msg = {"%s board: %s"}
M98 P"/macros/report/event.g" Y{var.msg} A{var.CAN_ADDRESS, var.ERROR_MESSAGE} F{var.CURRENT_FILE} V31300
M42 P{global.EMERGENCY_DISABLE_CTRL} S0 ; trip safety relay
; HALT the system -------------------------------------------------------------
M112