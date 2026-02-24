; Description:
; 	Configuration file for VIIO V2 3D printer
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/config.g"

; Let's make sure Daemon is not working ---------------------------------------
if(!exists(global.daemonStop))
	global daemonStop = true
set global.daemonStop = true

global errorMessage = ""
global errorRestartRequired = false
set global.hmiStateDetail = "board_configuring"

; 1. Enable the Logs ----------------------------------------------------------
M98 P"/sys/modules/logs/config.g"

; 2. Load FW configuration version --------------------------------------------
M98 P"/sys/modules/version/config.g"

;; Configuring variable for power failure call
global powerFailure = false
if(fileexists("/sys/resurrect.g"))
	set global.powerFailure = true
M400
; Configuring steps for print recovery from power failure
M911 S22 P"M913 X0 Y0 Z0" ;set the power failure voltage to 22, and currents of the axes to 0 

; 6. Set printer name ---------------------------------------------------------
M550 P"VIIO_V2"
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the printer name" F{var.CURRENT_FILE} E29002

; 7. VIIO V2 Configuration ----------------------------------------------------
; Change Y motor board address from 20 to 25
; 20 is default duet tool board.
M999 B20 B25

; Setting the modules for this machine ----------------------------------------
M98 P"/sys/modules/network/config.g"
M98 P"/sys/modules/emergency/config.g"
M98 P"/sys/modules/bed/config.g"
M98 P"/sys/modules/cbc/config.g"
M98 P"/sys/modules/doors/config.g"
M98 P"/sys/modules/lights/config.g"
M98 P"/sys/modules/probes/config.g"
M98 P"/sys/modules/axes/config.g"
M98 P"/sys/modules/power_meter/viio_config.g"
; Adding the extruder (T0 only) ------------------------------------------------
M98 P"/sys/modules/extruders/lgx_config.g"

; Enable Daemon
set global.daemonStop = false	
set global.hmiStateDetail = "board_configured"
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Done configuration of: VIIO_V2"}
M118 S{"[CONFIG] Done "^var.CURRENT_FILE}
M99