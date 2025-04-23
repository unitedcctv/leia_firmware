; Description: 	
;	This macro is called in the pause.g script to save the status of the homing of all axis
;---------------------------------------------------------------------------------------------
if(!exists(global.axesHomeStatus))
	global axesHomeStatus = vector(#move.axes,false)
else
	set global.axesHomeStatus = vector(#move.axes,false)
while(iterations < #move.axes)
	set global.axesHomeStatus[iterations] = move.axes[iterations].homed
M99