; This file was auto-generated.
; The tests version was created for the FW version "3.6.0.3"
;
; Description:
;   We wil make sure all the boards have the same FW version.
;	The expected version is: '3.6.0.3'
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/machine/firmware/abort_if_wrong_version.g"
M118 S{"[abort_if_wrong_version.g] Starting "^var.CURRENT_FILE}

; Test 1: 	Support a table with the boards and make sure everything matches. 
while iterations < #boards
	var FIRMWARE_VERSION = {""^boards[iterations].firmwareVersion}
	var CAN_ADDRESS = {""^(exists(boards[iterations].canAddress) ? boards[iterations].canAddress : "0")}
	var BOARD_NAME = "Unknown"
	var NOT_VALID = (var.FIRMWARE_VERSION!="3.6.0.3")

	if (var.NOT_VALID)
		if(var.CAN_ADDRESS == "0")
			set var.BOARD_NAME = "Main"
		elif(var.CAN_ADDRESS == "10")
			set var.BOARD_NAME = "X motor"
		elif(var.CAN_ADDRESS == "20")
			set var.BOARD_NAME = "Y motor"
		elif(var.CAN_ADDRESS == "30")
			set var.BOARD_NAME = "left Z motor"
		elif(var.CAN_ADDRESS == "31")
			set var.BOARD_NAME = "Right Z motor"
		elif(var.CAN_ADDRESS == "81")
			set var.BOARD_NAME = "T0"
		elif(var.CAN_ADDRESS == "82")
			set var.BOARD_NAME = "T1"
		
		M118 S{"[abort_if_wrong_version.g] Firmware version mismatch for CAN: "^var.CAN_ADDRESS^". Expected: 3.6.0.3 - Found: "^var.FIRMWARE_VERSION}
		M98 P"/macros/assert/abort.g" Y{"Invalid Firmware Version for "^var.BOARD_NAME^" board. Please update Firmware"}  F{var.CURRENT_FILE} E62310

; -----------------------------------------------------------------------------
M118 S{"[abort_if_wrong_version.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit