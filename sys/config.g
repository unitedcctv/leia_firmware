; Description: 	
;   Basic and minimum configuration of a generic machine.
;	The goal of this configuration file is to have a board with the
; 	minimum possible configuration that will not throw an error.
;   Assertions are not checked in /sys/config.g as it should be the minimum 
;	code possible.
;------------------------------------------------------------------------------

; General preferences ---------------------------------------------------------
G90						; send absolute coordinates...
M83						; relative extruder moves
M550 P"BR-DEFAULT"		; set the default name


; Network ---------------------------------------------------------------------
M552 P10.66.0.10 S1		; set IP Address
M553 P255.255.255.0		; set Netmask
M554 P10.66.0.20		; set Gateway

M586 P0 S1				; Enable HTTP
M586 P1 S1				; enable FTP

; Initialize HMI state to allow for recovery
global hmiStateDetail = "board_unconfigured"

; Start machine configuration -------------------------------------------------
M98 P"/sys/machines/config.g"

M99 ; Done