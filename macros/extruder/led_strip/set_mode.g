; Description: 	
;   Thsi macro is used by tool change and we cannot use "abort" https://docs.duet3d.com/en/User_manual/Tuning/Tool_changing
;   so we will use "M99" to exit and "M118" to report the error.
;	Set the mode of the LED strip base on the mode name.
; Input Parameters:
;	- T: Tool 0 or 1 where the filament monitor is connected
;	- S: State of the extruder. The supported states are:
;		+ "off"
;		+ "error"
;		+ "idle"
;		+ "selected"
;		+ "warning"
;		+ "out_of_filament"
;		+ "heating"
;		+ "cooling"
;		+ "on_temperature"
;		+ "manual"
;	- C (optional): It is expected a vector of length 3 with the RGB colors.
;					Each color should go from 0 (default) to 255 . 
;					(!) Only when the state is "manual".
; Example:
;	M98 P"/macros/extruder/led_strip/set_mode.g" T0 S"idle"
;	M98 P"/macros/extruder/led_strip/set_mode.g" T0 S"manual" C{255,0,0} ; Set it RED
; TODO:
;	- Support to effects: Using parameters Y (effect type) and W (effect time 
;	from 255 -> 25.5 sec).
;------------------------------------------------------------------------------

; LED strip support removed - this macro is now empty
M99

; Checking global variables and input parameters ------------------------------
if !exists(param.T)
	M118 S{"[set_mode.g] param.T does not exist"}
	M99 ; We can't continue.
M400
if param.T == null || param.T >= 2 || param.T < 0
	M118 S{"[set_mode.g] Unexpected value: param.T = " ^ param.T}
	M99 ; We can't continue.
M400
if !exists(param.S) || param.S == null
	M118 S{"[set_mode.g] param.S does not exist or is null"}
	M99 ; We can't continue.

if(!exists(global.extruderLedStrip))
	global extruderLedStrip = vector( 2 , null)


; Default values --------------------------------------------------------------
var colorManual = vector( 3 , 0 ) ; Default values of the color in "manual" state.

; Checking the mode -----------------------------------------------------------
var mode = null
if( param.S == "off" )
	set var.mode = 0
elif( param.S == "error" )
	set var.mode = 1
elif( param.S == "idle" )
	set var.mode = 2
elif( param.S == "selected" )
	set var.mode = 3
elif( param.S == "warning" )
	set var.mode = 4
elif( param.S == "out_of_filament" )
	set var.mode = 5
elif( param.S == "heating" )
	set var.mode = 6
elif( param.S == "cooling" )
	set var.mode = 7
elif( param.S == "on_temperature" )
	set var.mode = 8
elif( param.S == "manual")
	set var.mode = 9
	; Let's check the param.C
	if(!exists(param.C) || (exists(param.C) && param.C == null))
		M98 P"/macros/report/warning.g" Y"Expected input parameter C in ""manual"" state." F{var.CURRENT_FILE} W57620	
		M99 ; We can't continue.
	elif((#param.C != 3))
		M98 P"/macros/report/warning.g" Y"Input parameter C in ""manual"" state should be a vector of length 3" F{var.CURRENT_FILE} W57621
		M99 ; We can't continue.
	set var.colorManual = param.C
else
	M98 P"/macros/report/warning.g" Y"Code of mode is not supported" F{var.CURRENT_FILE} W57622
	M99 ; We can't continue.

M118 S{"[set_mode.g] Changing T"^param.T^" LEDs from "^global.extruderLedStrip[param.T]^" to "^param.S}
; Let's save the new state:
;	(!) If it is manual the we will have a vector with 2 values {state, {R,G,B}},
;		otherwise, it will be a vector of length 1 {state,}.
var IS_MANUAL_STATE = (param.S == "manual")
var newState = vector( { var.IS_MANUAL_STATE ? 2 : 1 }, null )
set var.newState[0] = param.S
if(var.IS_MANUAL_STATE)
	set var.newState[1] = var.colorManual
set global.extruderLedStrip[param.T] = var.newState

; Omit if it is an emulator board ---------------------------------------------
if (network.hostname == "emulator") 
	M99

; Set the LED strip -----------------------------------------------------------
M150 E{param.T} S{var.mode} R{var.colorManual[0]} U{var.colorManual[1]} B{var.colorManual[2]}

; -----------------------------------------------------------------------------
M99