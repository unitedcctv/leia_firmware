; Review Date: 		??.??.??
; Description:
;	We will reset all the expansion boards and then the main board with small
;	delays to make sure they go off.
; -----------------------------------------------------------------------------
; Turning off the emergency ---------------------------------------------------
; This goes first!
if(exists(global.EMERGENCY_DISABLE_CTRL))
	M42 P{global.EMERGENCY_DISABLE_CTRL} S0

; Start with the file ---------------------------------------------------------
M98 P"/macros/report/event.g" Y{"Restarting the boards"}  F"/macros/boards/reset_all.g" V52100

; Definitions -----------------------------------------------------------------
; var MOTOR_OFF_DELAY 	= 0.01 	; [sec] Max. time waiting the motors to go off.
; var RESET_MESSAGE_DALAY = 0.01	; [sec] Delay before starting reseting the expansion boards
; var RESET_BOARD_DELAY 	= 0.01	; [sec] Delay between board resets.

; Turning off motors ----------------------------------------------------------
; M118 S{"[BOARD] Turning off the motors"}
; M18  	; Turn off the motors
; G4 S{var.MOTOR_OFF_DELAY}

; Reseting boards -------------------------------------------------------------
; M98 P"/macros/report/warning.g" Y{"Reseting in boards in:"^var.RESET_MESSAGE_DALAY}  F{var.CURRENT_FILE} W52101
; G4 S{var.RESET_MESSAGE_DALAY}

; First the expansion boards --------------------------------------------------
; if(#boards > 1)
;	; Let's copy the boards because they reconnect and change the vector length
;	var boardsCanAddresses = vector(#boards-1, 0)
;	var boardIndex = 1 ; Omit the first one (Always Main-Board)
;	while (var.boardIndex < #boards)
;		set var.boardsCanAddresses[var.boardIndex-1] = boards[var.boardIndex].canAddress
;		set var.boardIndex = var.boardIndex + 1
;	; Reset all the CAN-Addresses in the vector
;	set var.boardIndex = 0 
;	while (var.boardIndex < #var.boardsCanAddresses)
;		M999 B{var.boardsCanAddresses[var.boardIndex]}
;		G4 S{var.RESET_BOARD_DELAY}
;		set var.boardIndex = var.boardIndex + 1

; Now the Main board
M999 B0