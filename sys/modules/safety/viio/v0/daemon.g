; Description: 	
;		Check if the temperature is high and close the door
;---------------------------------------------------------------------------------------------

if ((heat.heaters[0].current > global.bedHazardousTemp) && (global.doorIsLocked == false))
	M98 P"/macros/report/warning.g" Y"Bed temperature is greater than 99°C. Locking the door." F"/sys/modules/safety/viio/v0/daemon.g" W51310
	M98 P"/macros/doors/lock.g"
M99