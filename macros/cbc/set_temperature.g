; Description: 	THIS FILE NEEDS TO BE OVERWRITTEN BY THE CONFIGURATION
;	 Input Parameters:
;		  - T (optional): Target Temperature [ºC] to set in the CBC. If 0, the fans are 
;						 heaters are off.
;		  - D (optional): Max. Difference between the target temperature [ºC] and the 
;						 current one.
;---------------------------------------------------------------------------------------------
M98 P"/macros/report/warning.g" Y"Not supported! Missing link" F"/macros/cbc/set_temperature.g" W53100
M99 ; Nothing is done