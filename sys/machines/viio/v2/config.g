; Description:
; 	Basic configuration of the VIIO V2
;------------------------------------------------------------------------------

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
M98 P"/macros/extruder/automatic_detection.g" T0
M98 P"/macros/extruder/automatic_detection.g" T1

M98 P"/sys/modules/fhx/viio/v0/config.g"			; FHX			VIIO 	v0

; -----------------------------------------------------------------------------
M99