; Description:
; 	This test will check that the input voltages of the boards have the right 
;	values.
; 	NOTE: Consider that the emergency circuit powers off the 48V line.
; 
; Input Arguments:
;	- (Optional) S: If S != 0, any voltage errors will not 'abort'.
; Results:
; 	The return values are passed via global.resultTestVoltages and they can be:
; 		- 0: OK
; 		- 1: Warning
;	 	- 2: Error
; -----------------------------------------------------------------------------
var CURRENT_FILE = "/macros/sensors/voltages/check_all.g"
M118 S{"[SENSORS] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

if(exists(global.resultTestVoltages))
	set global.resultTestVoltages = 2
else
	global resultTestVoltages = 2
	G4 S0.1
M400

; Definitions -----------------------------------------------------------------
var VIN_MIN = { (network.hostname == "emulator") ? 18.0  : 20.0 } 	; [V] Minimum Vin Voltage
var VIN_MAX = 26.0 	; [V] Maximum Vin Voltage
var V48_MIN = 20.0 	; [V] Maximum V48 Voltage
var V48_MAX = 50.0 	; [V] Maximum V48 Voltage
var boardName = ""

; Input arguments
var ABORT_ENABLED = {(exists(param.S) && param.S != 0) ? false : true }

; Checking voltages -----------------------------------------------------------
while iterations < #boards
	if !exists(boards[iterations].canAddress)
		set var.boardName = "Main Board"
	elif(boards[iterations].canAddress == 0)
		set var.boardName = "Main board"
	elif(boards[iterations].canAddress == 10)
		set var.boardName = "X axis board"
	elif(boards[iterations].canAddress == 25)
		set var.boardName = "Y axis board"
	elif(boards[iterations].canAddress == 30)
		set var.boardName = "Z axis left board"
	elif(boards[iterations].canAddress == 31)
		set var.boardName = "Z axis right board"
	elif(boards[iterations].canAddress == 20)
		set var.boardName = "T0 board"

	;checking for the voltages
	; If board is T0, bypass voltage checks
	if(boards[iterations].canAddress == 20)
		M118 S{"[SENSORS] Skipping voltage checks for T0 board"} F{var.CURRENT_FILE}
		continue
	if(boards[iterations].vIn.current < var.VIN_MIN )
		M98 P"/macros/assert/abort_if.g" R{var.ABORT_ENABLED} Y{"Under-Voltage in Vin of %s"} A{var.boardName,}   F{var.CURRENT_FILE} E67310
		M98 P"/macros/report/warning.g" Y{"Under-Voltage in Vin of %s"} A{var.boardName,} F{var.CURRENT_FILE} W67310
		M99 ; Not an abort as we may be printing
	if(boards[iterations].vIn.current > var.VIN_MAX)
		M98 P"/macros/assert/abort_if.g" R{var.ABORT_ENABLED} Y{"Over-Voltage in Vin of %s"} A{var.boardName,}	F{var.CURRENT_FILE} E67311
		M98 P"/macros/report/warning.g" Y{"Over-Voltage in Vin of %s"} A{var.boardName,} F{var.CURRENT_FILE} W67311
		M99 ; Not an abort as we may be printing
	if ( exists(boards[iterations].v48.current) )
		if(boards[iterations].v48.current < var.V48_MIN)
			M98 P"/macros/assert/abort_if.g" R{var.ABORT_ENABLED} Y{"Under-Voltage in V48 of %s"} A{var.boardName,}  F{var.CURRENT_FILE} E67312
			M98 P"/macros/report/warning.g" Y{"Under-Voltage in Vin of %s"} A{var.boardName,} F{var.CURRENT_FILE} W67312
			M99 ; Not an abort as we may be printing
		if(boards[iterations].v48.current > var.V48_MAX)
			M98 P"/macros/assert/abort_if.g" R{var.ABORT_ENABLED} Y{"Over-Voltage in V48 of %s"} A{var.boardName,}	F{var.CURRENT_FILE} E67313
			M98 P"/macros/report/warning.g" Y{"Over-Voltage in V48 of %s"} A{var.boardName,} F{var.CURRENT_FILE} W67313
			M99 ; Not an abort as we may be printing
; We pass the test, let's return the proper value
set global.resultTestVoltages = 0 ; PASS!

M400

M118 S{"[SENSORS] Done "^var.CURRENT_FILE}
M99 ; Proper exit