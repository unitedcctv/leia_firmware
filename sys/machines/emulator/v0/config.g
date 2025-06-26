; Description: 	
; 	Basic configuration of the Emulator V0
;------------------------------------------------------------------------------
; Setting the modules for this machine ----------------------------------------
M98 P"/sys/modules/network/emulator/v0/config.g"
M98 P"/sys/modules/emergency/emulator/v0/config.g"
M98 P"/sys/modules/axes/emulator/v0/config.g"
M98 P"/sys/modules/bed/emulator/v0/config.g"
M98 P"/sys/modules/cbc/emulator/v0/config.g"
M98 P"/sys/modules/doors/emulator/v0/config.g"
M98 P"/sys/modules/lights/emulator/v0/config.g"
M98 P"/sys/modules/probes/emulator/v0/config.g"
M98 P"/sys/modules/stage/emulator/v0/config.g"
M98 P"/sys/modules/power_meter/rnd/v0/config.g"
M98 P"/sys/modules/xy_calibration/viio/v0/config.g"	; XY Calibra.	VIIO	v0

; Adding the extruder if they are connected -----------------------------------
M98 P"/sys/modules/extruders/lgx/v0/config.g" T0
M98 P"/sys/modules/fhx/emulator/config.g"			; FHX			VIIO 	v0
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Done configuration of EMULATOR V0"}
M99