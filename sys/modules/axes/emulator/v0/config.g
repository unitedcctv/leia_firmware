; Description:
; 	All the motors related to the portal are configured in this file. So the axes affected
;	are:
;		+ X
;		+ Y
;		+ Z
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/emulator/v0/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_AXES)}  Y{"A previous AXES configuration exists"} F{var.CURRENT_FILE}  E10160

; DEFINITIONS -----------------------------------------------------------------
var X_ENDSTOP_PORT = "0.io0.in"			; Endstops in X
var Y_ENDSTOP_PORT = "0.io1.in"			; Endstops in Y
var Z_ENDSTOP_PORT = "0.io2.in"			; Endstops in Z

var X_STEP_MM_NO_MICROSTEP  = 1.8018	; [step/mm] Steps per mm without microstepping in X
var X_MICROSTEPPING		 	= 16		; [] Microstepping in X
var Y_STEP_MM_NO_MICROSTEP  = 1.8018	; [step/mm] Steps per mm without microstepping in Y
var Y_MICROSTEPPING		 	= 16		; [] Microstepping in Y
var Z_STEP_MM_NO_MICROSTEP  = 49.9219	; [step/mm] Steps per mm without microstepping in Z
var Z_MICROSTEPPING		 	= 16		; [] Microstepping in Z

; Axes Dimensions
global printingLimitsX = {0 , 1000}	; [mm] Min and max point allowed to print in X
global printingLimitsY = {0 , 500}	; [mm] Min and max point allowed to print in Y
global printingLimitsZ = {0 , 500}	; [mm] Min and max point allowed to print in Z

; Loading measured length values
var X_AXIS_LENGTH 		= 1080 ;[mm] X Axis length
var Y_AXIS_LENGTH 		= 611  ;[mm] Y Axis length
var Z_AXIS_LENGTH 		= 508  ;[mm] Z Axis length

var X_AXIS_MAX			= global.printingLimitsX[1]	; [mm] Axis maximum
var Y_AXIS_MAX			= 530.00	; [mm] Axis maximum
var Z_AXIS_MAX			= global.printingLimitsZ[1]	; [mm] Axis maximum

var X_AXIS_MIN 			= {var.X_AXIS_MAX - var.X_AXIS_LENGTH}	; [mm] Axis minimum
var Y_AXIS_MIN 			= {var.Y_AXIS_MAX - var.Y_AXIS_LENGTH}	; [mm] Axis minimum
var Z_AXIS_MIN 			= {var.Z_AXIS_MAX - var.Z_AXIS_LENGTH}	; [mm] Axis minimum

; Calculating parameters
var X_STEP_MM = {var.X_STEP_MM_NO_MICROSTEP * var.X_MICROSTEPPING}
var Y_STEP_MM = {var.Y_STEP_MM_NO_MICROSTEP * var.Y_MICROSTEPPING}
var Z_STEP_MM = {var.Z_STEP_MM_NO_MICROSTEP * var.Z_MICROSTEPPING}

; Nozzle wiper Positions for tools in X and Y {tool0, tool1}
global WIPER_X_POSITIONS		= {0, -25}
global WIPER_Y_POSITIONS 		= {var.Y_AXIS_MIN, var.Y_AXIS_MAX}
global TOOL_WIPING_POS			= {5, 5}
global wiperPresent				= false
global jobBBOX					= null
; Loading the Wiper existence status
M98 P"/macros/variable/load.g" N"global.wiperPresent"  ; Will be null if not existing
M598
if (global.savedValue == null)
	M118 S{"[CONFIG] No nozzle wiper found, using default values"}
else
	M118 S{"[CONFIG] Loaded bed touch values: " ^ global.savedValue}
	set global.wiperPresent = global.savedValue

; Loading the job bounding box from the last started job if we had a power failure
if (exists(global.powerFailure) && global.powerFailure)
	M98 P"/macros/variable/load.g" N"global.jobBBOX"  ; Will be null if not existing
	M118 S{"[CONFIG] Loaded the previous job bounding box to the global: " ^ global.savedValue}
M400

; Motors ----------------------------------------------------------------------
; Direction
M569 P0.0 S0 ; X - Motor 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of X 0" F{var.CURRENT_FILE} E10161
M569 P0.1 S0 ; Y - Motor 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Y 0" F{var.CURRENT_FILE} E10162
M569 P0.2 S0 ; Z - Motor 0
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Z 0" F{var.CURRENT_FILE} E10163

; Mapping
M584 X0.0 	; Set drive mapping for X
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axis X" F{var.CURRENT_FILE} E10164
M584 Y0.1 	; Set drive mapping for Y
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axes Y" F{var.CURRENT_FILE} E10165
M584 Z0.2   ; Set drive mapping for Z
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axes Z" F{var.CURRENT_FILE} E10166

; Microstepping
M350 X{var.X_MICROSTEPPING} I1	; Configure microstepping with interpolation in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in X" F{var.CURRENT_FILE} E10167
M350 Y{var.Y_MICROSTEPPING} I1	; Configure microstepping with interpolation in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in Y" F{var.CURRENT_FILE} E10168
M350 Z{var.Z_MICROSTEPPING} I1	; Configure microstepping with interpolation in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in Z" F{var.CURRENT_FILE} E10169

; Steps per mm
M92  X{var.X_STEP_MM} 	; [step/mm] Set steps per mm in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in X" F{var.CURRENT_FILE} E10170
M92  Y{var.Y_STEP_MM} 	; [step/mm] Set steps per mm in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in Y" F{var.CURRENT_FILE} E10171
M92  Z{var.Z_STEP_MM}	; [step/mm] Set steps per mm in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in Z" F{var.CURRENT_FILE} E10172

; Maximum instantaneous speed changes
M566 X600.00	; [mm/min] Set maximum instantaneous speed changes in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in X" F{var.CURRENT_FILE} E10173
M566 Y600.00 	; [mm/min] Set maximum instantaneous speed changes in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in Y" F{var.CURRENT_FILE} E10174
M566 Z10.0		; [mm/min] Set maximum instantaneous speed changes in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in Z" F{var.CURRENT_FILE} E10175

; Maximum speeds
M203 X30000.00 	; [mm/min] Set maximum speeds in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in X" F{var.CURRENT_FILE} E10176
M203 Y30000.00 	; [mm/min] Set maximum speeds in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in Y" F{var.CURRENT_FILE} E10177
M203 Z400.00 	; [mm/min] Set maximum speeds in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in Z" F{var.CURRENT_FILE} E10178

; Accelerations
M201 X3000.00 	; [mm/s^2] Set acceleration in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the accelerations in X" F{var.CURRENT_FILE} E10179
M201 Y3000.00 	; [mm/s^2] Set acceleration in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the accelerations in Y" F{var.CURRENT_FILE} E10180
M201 Z200.0		; [mm/s^2] Set acceleration in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the accelerations in Z" F{var.CURRENT_FILE} E10181

; Current and idle factor
M906 X2000	; [mA] Set motor currents in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in X driver" F{var.CURRENT_FILE} E10182
M906 Y2000 	; [mA] Set motor currents in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in Y driver" F{var.CURRENT_FILE} E10183
M906 Z2000 	; [mA] Set motor currents in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in Z driver" F{var.CURRENT_FILE} E10184
M906 I30 T30 ; [%][sec] Set drivers idle factor and timeout
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the idle factor and timeout" F{var.CURRENT_FILE} E10185

; Axis Limits  ----------------------------------------------------------------
M208 X{var.X_AXIS_MIN} 	S1  ; set axis minima in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for X" F{var.CURRENT_FILE} E10186
M208 Y{var.Y_AXIS_MIN} 	S1  ; set axis minima in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Y" F{var.CURRENT_FILE} E10187
M208 Z{var.Z_AXIS_MIN} 	S1  ; set axis minima in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Z" F{var.CURRENT_FILE} E10188
M208 X{var.X_AXIS_MAX} 	S0	; set axis maxima in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for X" F{var.CURRENT_FILE} E10189
M208 Y{var.Y_AXIS_MAX} 	S0  ; set axis maxima in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Y" F{var.CURRENT_FILE} E10190
M208 Z{var.Z_AXIS_MAX} 	S0  ; set axis maxima in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Z" F{var.CURRENT_FILE} E10191

; Endstops --------------------------------------------------------------------
M574 X1 S1 P"0.io0.in" ; configure active-high endstop for low end on X via pin io0.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for X" F{var.CURRENT_FILE} E10192
M574 Y1 S1 P"0.io1.in" ; configure active-high endstop for low end on Y via pin io1.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for Y" F{var.CURRENT_FILE} E10193
M574 Z2 S1 P"0.io2.in" ; configure active-high endstop for high end on Z via pin io2.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for Z" F{var.CURRENT_FILE} E10194

; CONFIGURATION ---------------------------------------------------------------
; NOTE: (!) THIS CONFIGURATION MAY NEED TO REDIRECT THE homex.g, homey.g homexy.g homez.g ....
; Creating links:
M98 P"/macros/files/link/create.g" L"/sys/homex.g"	D"/sys/modules/axes/emulator/v0/homing/x.g"
M98 P"/macros/files/link/create.g" L"/sys/homexy.g"	D"/sys/modules/axes/emulator/v0/homing/xy.g"
M98 P"/macros/files/link/create.g" L"/sys/homey.g"	D"/sys/modules/axes/emulator/v0/homing/y.g"
M98 P"/macros/files/link/create.g" L"/sys/homez.g"	D"/sys/modules/axes/emulator/v0/homing/z.g"
M98 P"/macros/files/link/create.g" L"/sys/hometozmax.g"	D"/sys/modules/axes/emulator/v0/homing/zmax.g" I{null}

global MODULE_AXES = 0.1	; Setting the current version of this module
; -----------------------------------------------------------------------------
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99 ; Proper exit