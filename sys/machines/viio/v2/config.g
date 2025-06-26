; Description:
; 	Basic configuration of the VIIO V2
;------------------------------------------------------------------------------

; Change Y motor board address from 20 to 25
; 20 is default duet tool board.
M999 B20 B25

; Setting the modules for this machine ----------------------------------------
M98 P"/sys/modules/network/viio/v0/config.g"
M98 P"/sys/modules/emergency/viio/v1/config.g"
M98 P"/sys/modules/bed/viio/v0/config.g"
M98 P"/sys/modules/cbc/viio/v1/config.g"
M98 P"/sys/modules/doors/viio/v0/config.g"
M98 P"/sys/modules/lights/viio/v1/config.g"
M98 P"/sys/modules/probes/viio/v1/config.g"
M98 P"/sys/modules/axes/viio/v2/config.g"
M98 P"/sys/modules/power_meter/viio/v0/config.g"
M98 P"/sys/modules/xy_calibration/viio/v0/config.g"

; Adding the extruder if they are connected -----------------------------------
M98 P"/sys/modules/extruders/lgx/v0/config.g" T0


; -----------------------------------------------------------------------------
M99