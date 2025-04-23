; File Name: 		/sys/modules/version/config.g
; File Version: 	0.1
; Author: 			FABBRO
; Creation Date: 	10.07.23
; Reviewer: 		????
; Review Date: 		??.??.23
; Description: 	
;	This file is auto generated with "create_configuration.py". The 
;	configuration version is unique.
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/version/config.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_VERSION)}      Y{"A previous VERSION configuration exists"} 	F{var.CURRENT_FILE}	E16600
M98 P"/macros/assert/abort_if.g" R{exists(global.CONFIGURATION_UUID)}  Y{"A previous global CONFIGURATION_UUID exists"} F{var.CURRENT_FILE} E16601
M98 P"/macros/assert/abort_if.g" R{exists(global.CONFIGURATION_TIME)}  Y{"A previous global CONFIGURATION_TIME exists"} F{var.CURRENT_FILE} E16602

; Creating the global variables of this configuration -------------------------
global CONFIGURATION_UUID = "3.6.3.3"
global CONFIGURATION_TIME = 1741961614

M118 S{"[CONFIG] Using configuration "^global.CONFIGURATION_UUID^" created at "^global.CONFIGURATION_TIME}

; Module version --------------------------------------------------------------
global MODULE_VERSION = 0.1        ; Setting the current version of this module

; -----------------------------------------------------------------------------
M118 S{"Configured: "^var.CURRENT_FILE}
M99 ; Proper exit