; This file was auto-generated.
; The tests version was created for the FW version "3.6.0.3"
;
; Description:
;	This test should be run every time the machine is updated and can be executed
;	every time the machine is turned on.
; Test:
;	1.  Check that all the boards connected to the CAN-Bus and the XBoard have the 
;		right version
; Results:
;	The result value is stored in global.hwTestResult
;		* 0 = `PASS`
;		* 1 = `PASS WITH COMMENTS`
;		* 2 = `NOT PASS`
;		* 3 = `ERROR`
;	The result message is stored in global.hwTestMessage
;		* `PASS`: The test PASS
;		* `PASS WITH COMMENTS: <comment>`: It passed but there is a comment
;		* `NOT PASS: <comment>`: The test didn't passed.
;		* `ERROR: <comment>`: The test couldn't be completed.
;	The name of the file is returned via global.hwTestName.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/machine/firmware/version_check" ; Name of the current file.

; Check if global variables are present
if(!exists(global.hwTestName))
	global hwTestName = ""
if(!exists(global.hwTestMessage))
	global hwTestMessage = ""
if(!exists(global.hwTestResult))
	global hwTestResult = 3

set global.hwTestResult = 3
set global.hwTestMessage = "ERROR: Could not complete the test '" ^ {var.CURRENT_FILE} ^ "'"
; Set the file name
set global.hwTestName = {var.CURRENT_FILE}^ ".g"

; Test 1: 	Support a table with the boards and make sure everything matches. 
while true
	if iterations >= #boards
		break
	if( (""^boards[iterations].firmwareVersion) != "3.6.0.3" )
		set global.hwTestResult = 2
		if( exists(boards[iterations].canAddress) )
			set global.hwTestMessage = {"NOT PASS: Version in Board " ^ {boards[iterations].canAddress} ^ " is not right: " ^ {boards[iterations].firmwareVersion} ^ " != 3.6.0.3"}
			M118 S{var.CURRENT_FILE ^" - NOT PASS: Version in Board " ^ {boards[iterations].canAddress} ^ " is not right: " ^ {boards[iterations].firmwareVersion} ^ " != 3.6.0.3"}
		else
			set global.hwTestMessage = {"NOT PASS: Version in boards[" ^ iterations ^ "] is not right: " ^ {boards[iterations].firmwareVersion} ^ " != 3.6.0.3"}
			M118 S{var.CURRENT_FILE ^" - NOT PASS: Version in boards[" ^ iterations ^ "] is not right: " ^ {boards[iterations].firmwareVersion} ^ " != 3.6.0.3"}
		M99 ; Exit current file

; The test PASSED -------------------------------------------------------------
set global.hwTestResult = 0
set global.hwTestMessage = "PASS"
M118 S{var.CURRENT_FILE^" - PASS"}