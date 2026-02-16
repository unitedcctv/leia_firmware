; Description:
; 	All the motors related to the portal are configured in this file. So the
;	axes affected are:
;		+ X
;		+ Y
;		+ Z
; Changelog:
;	- The default dimension of the machine was changed for the new endstops.
;	- SUpport to single endstop in X
; TODO:
;	- Support motors with expressions and arrays not supported in 3.5.0
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/axes/config.g"
M118 S{"[CONFIG] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/variable/load.g"} F{var.CURRENT_FILE} E10530
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{exists(global.MODULE_AXES)}  Y{"A previous AXES configuration exists"} F{var.CURRENT_FILE}  E10531
M98 P"/macros/assert/abort_if.g" R{!exists(global.MODULE_PROBES)}  Y{"Missing PROBES configuration"} F{var.CURRENT_FILE}  E10532
M98 P"/macros/assert/abort_if.g" R{(global.MODULE_PROBES < 0.2)}  Y{"Modules PROBES version not valid"} F{var.CURRENT_FILE}  E10533

; DEFINITIONS -----------------------------------------------------------------

; Motors
var X_MOTOR_DRIVER_F	= 10.0		; Set motor driver number for X Motor, back
var X_MOTOR_DRIVER_B	= 10.1		; Set motor driver number for X Motor, front
var Y_MOTOR_DRIVER		= 25.0		; Set motor driver number for Y Motor
var Z_MOTOR_DRIVER_L_F	= 30.1		; Set motor driver number for Z Motor, left, front
var Z_MOTOR_DRIVER_L_B	= 30.0		; Set motor driver number for Z Motor, left, back
var Z_MOTOR_DRIVER_R_F	= 31.0		; Set motor driver number for Z Motor, right, front
var Z_MOTOR_DRIVER_R_B	= 31.1		; Set motor driver number for Z Motor, right, back

; Gearbox
var GEARBOXES_INSTALLED = fileexists("/sys/modules/axes/_gearboxes_installed.txt")

; Endstops
var X_ENDSTOP_PORT 		= "!10.io3.in"
var Y_ENDSTOP_PORT 		= "!25.io0.in"
var Z_ENDSTOP_PORT 		= "!30.io0.in+!30.io3.in+!31.io0.in+!31.io3.in"

; Motion parameters
var X_MAX_SPEED_MM 		= 30000.00	; [mm/min] Maximum speed for X Motor
var Y_MAX_SPEED_MM		= 30000.00	; [mm/min] Maximum speed for Y Motor
var Z_MAX_SPEED_MM		= 600.00	; [mm/min] Maximum speed for Z Motor

var X_MAX_SPEED_CHANGE	= 500.00	; [mm/min] Maximum instantanous speed changes for X Motor
var Y_MAX_SPEED_CHANGE	= 500.00	; [mm/min] Maximum instantanous speed changes for Y Motor
var Z_MAX_SPEED_CHANGE	= 10.0		; [mm/min] Maximum instantanous speed changes for Z Motor

var X_ACCEL				= 3000.00	; [mm/s^2] Acceleration for X Motor
var Y_ACCEL				= 3000.00	; [mm/s^2] Acceleration for Y Motor
var Z_ACCEL				= 200.00	; [mm/s^2] Acceleration for Z Motor

var PRINT_ACCEL			= 1200		; [mm/s^2] Acceleration for Printing
var TRAVEL_ACCEL		= 1400		; [mm/s^2] Acceleration for Travel

var X_MOTOR_CURRENT 	= 4200.00	; [mA] X Motor peak current: 70% rated peak (4.24 [A RMS] x 1.414)
var Y_MOTOR_CURRENT 	= 4200.00	; [mA] Y Motor peak current: 70% rated peak (4.24 [A RMS] x 1.414)
var Z_MOTOR_CURRENT 	= 1500.00	; [mA] Z Motor peak current: 50% rated peak (2.12 [A RMS] x 1.414)

var IDLE_FACTOR 		= 30.00		; [%] Motor Idle factor
var IDLE_TIMEOUT		= 30		; [sec] Motor Idle Timeout

; Input Shaping
global SYSID_PEAK_THRS			= 0.1											; [g]
global inputShapingOmega    	= 30											; [Hz] Default center frequency for input shaping
global inputShapingDamping     	= 0.1											; [] Default damping ratio
M593 P"ei2" F{global.inputShapingOmega} S{global.inputShapingDamping} 			; Set input shaping

; Axes Dimensions
global printingLimitsX = {0 , 1050}	; [mm] Min and max point allowed to print in X
global printingLimitsY = {0 , 430}	; [mm] Min and max point allowed to print in Y
global printingLimitsZ = {0 , 430}	; [mm] Min and max point allowed to print in Z

; Loading measured length values
var requiresMeasureLength = 0
var X_AXIS_LENGTH 		= 1050 	; [mm] Total X-Axis length
var Y_AXIS_LENGTH 		= 430 	; [mm] Total Y-Axis length
var Z_AXIS_LENGTH 		= 422 	; [mm] Total Z-Axis length

if(var.requiresMeasureLength > 0)
	M98 P"/macros/report/warning.g" Y{"Requires calibration using measure_length.g"} F{var.CURRENT_FILE} W10530
var X_MIN_EXTRUDER_OFFSET = -15.00	; [mm] Min. extruder offset
var X_AXIS_MAX			= global.printingLimitsX[1] - var.X_MIN_EXTRUDER_OFFSET	; [mm] Axis maximum
; var Y_AXIS_MAX			= 500.00 + ((var.Y_AXIS_LENGTH - 500) / 2)	; [mm] Axis maximum

var X_AXIS_MIN 			= {var.X_AXIS_MAX - var.X_AXIS_LENGTH}	; [mm] Axis minimum
var Y_AXIS_MIN 			= -50	; [mm] Axis minimum
var Z_AXIS_MIN 			= -8		; [mm] Axis minimum

var Y_AXIS_MAX 			= var.Y_AXIS_LENGTH + var.Y_AXIS_MIN	; [mm] Axis maximum
var Z_AXIS_MAX			= var.Z_AXIS_LENGTH + var.Z_AXIS_MIN	; [mm] Axis maximum

var X_ENDSTOP_TYPE 		= 1			; [1-4] 1=switch type endstop, 2=z-probe, 3=single motor load detection, 4=multiple motor load detection
var Y_ENDSTOP_TYPE 		= 1			; [1-4] 1=switch type endstop, 2=z-probe, 3=single motor load detection, 4=multiple motor load detection
var Z_ENDSTOP_TYPE 		= 1			; [1-4] 1=switch type endstop, 2=z-probe, 3=single motor load detection, 4=multiple motor load detection

var X_ENDSTOP_POSITION 	= 1			; [0-2] 0=none, 1=low end, 2=high end
var Y_ENDSTOP_POSITION 	= 1			; [0-2] 0=none, 1=low end, 2=high end
var Z_ENDSTOP_POSITION 	= 2			; [0-2] 0=none, 1=low end, 2=high end
var Z_ANALOG_ENDSTOP_POSITION 	= 1 ; [0-2] 0=none, 1=low end, 2=high end

; Calculating parameters
; Microsteps
var X_STEP_MM_NO_MICROSTEP  = 1.8018
var X_MICROSTEPPING			= 64
var Y_STEP_MM_NO_MICROSTEP  = 1.8018
var Y_MICROSTEPPING		 	= 64
var Z_STEP_MM_NO_MICROSTEP  = 49.9219
var Z_MICROSTEPPING		 	= 32

if (var.GEARBOXES_INSTALLED)
	set var.X_STEP_MM_NO_MICROSTEP  = 5.0 * 1.8018
	set var.X_MICROSTEPPING			= 32
	set var.Y_STEP_MM_NO_MICROSTEP  = 5.0 * 1.8018
	set var.Y_MICROSTEPPING		 	= 32
	set var.X_MOTOR_CURRENT 		= 2800.00	; [mA] X Motor peak current: 70% rated peak (2.82 [A RMS] x 1.414)
	set var.Y_MOTOR_CURRENT 		= 2800.00	; [mA] Y Motor peak current: 70% rated peak (2.82  [A RMS] x 1.414)
	;var X_BACKLASH					= 0.01		; [mm] Backlash compensation for X axis (10 arcmin from gearboxes datasheet)
	;var Y_BACKLASH					= 0.01		; [mm] Backlash compensation for Y axis (10 arcmin from gearboxes datasheet)
	;M425 X{var.X_BACKLASH} Y{var.Y_BACKLASH}

var X_STEP_MM = {var.X_STEP_MM_NO_MICROSTEP * var.X_MICROSTEPPING}	; [step/mm] Motorsteps per mm
var Y_STEP_MM = {var.Y_STEP_MM_NO_MICROSTEP * var.Y_MICROSTEPPING}	; [step/mm] Motorsteps per mm
var Z_STEP_MM = {var.Z_STEP_MM_NO_MICROSTEP * var.Z_MICROSTEPPING}	; [step/mm] Motorsteps per mm

var AXIS_MINIMUM_PARAMETER = 1		; [bool] Set axis maximum (default), 1 = set axis minimum
var AXIS_MAXIMUM_PARAMETER = 0		; [bool] Set axis maximum (default), 1 = set axis minimum

var ENDSTOP_TRIGGERING_POINT	= -500		; [um] Point where the endstops Zmin is triggered
var EMERGENCY_TRIGGERING_POINT	= -2500		; [um] Point where the emergency is triggered

; Get the input ID for the emergency
M98 P"/macros/get_id/input.g"
var EMERGENCY_INPUT_ID = global.inputId
; Get the trigger ID for the emergency
M98 P"/macros/get_id/trigger.g"
var EMERGENCY_TRIGGER_ID = global.triggerId 				; Trigger id called when the event is


; Check for availability of X,Y,Z motorboards----------------------------------
M98 P"/macros/assert/board_present.g" D10 Y"X axis motor board is required for axes" F{var.CURRENT_FILE} E10542
M98 P"/macros/assert/board_present.g" D25 Y"Y axis motor board is required for axes" F{var.CURRENT_FILE} E10543
M98 P"/macros/assert/board_present.g" D30 Y"Z axis left motor board is required for axes" F{var.CURRENT_FILE} E10544
M98 P"/macros/assert/board_present.g" D31 Y"Z axis right motor board is required for axes" F{var.CURRENT_FILE} E10545

; Motor Drivers setup----------------------------------------------------------
M569 P{var.X_MOTOR_DRIVER_F} S0	Y6:0 F3 B1 ;D3 V200 H100	; X - Motor 0	-> S0 for turning cw, Stealthchop thigh 100 (260.2 mm/sec), tpwmthrs 200 (130.1 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of X 0" F{var.CURRENT_FILE} E10546
M569 P{var.X_MOTOR_DRIVER_B} S1 Y6:0 F3 B1 ;D3 V200 H100	; X - Motor 1	-> S1 for turning cw, Stealthchop thigh 100 (260.2 mm/sec), tpwmthrs 200 (130.1 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of X 1" F{var.CURRENT_FILE} E10547

M569 P{var.Y_MOTOR_DRIVER} S0 Y6:0 F3 B1 ;D3 V200 H100		; Y - Motor 	-> S0 for turning cw, Stealthchop thigh 100 (260.2 mm/sec), tpwmthrs 200 (130.1 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Y 0" F{var.CURRENT_FILE} E10550

M569 P{var.Z_MOTOR_DRIVER_L_F} S1 Y6:0 F3 B1 ;D3 H50 V75 	; Z - Motor 0	-> S1 for turning cw, Stealthchopthigh 50 (18.8 mm/sec), tpwmthrs 75 (12.5 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Z 0" F{var.CURRENT_FILE} E10551
M569 P{var.Z_MOTOR_DRIVER_L_B} S1 Y6:0 F3 B1 ;D3 H50 V75	; Z - Motor 1	-> S1 for turning cw, Stealthchopthigh 50 (18.8 mm/sec), tpwmthrs 75 (12.5 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Z 1" F{var.CURRENT_FILE} E10552
M569 P{var.Z_MOTOR_DRIVER_R_F} S1 Y6:0 F3 B1 ;D3 H50 V75	; Z - Motor 2	-> S1 for turning cw, Stealthchopthigh 50 (18.8 mm/sec), tpwmthrs 75 (12.5 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Z 2" F{var.CURRENT_FILE} E10553
M569 P{var.Z_MOTOR_DRIVER_R_B} S1 Y6:0 F3 B1 ;D3 H50 V75	; Z - Motor 3	-> S1 for turning cw, Stealthchopthigh 50 (18.8 mm/sec), tpwmthrs 75 (12.5 mm/sec), HSTART:HEND 6:0, TOFF 3, TBL 1
M98 P"/macros/assert/result.g" R{result} Y"Unable to set the motor direction of Z 3" F{var.CURRENT_FILE} E10554

; Mapping
; Expressions and arrays not supported in 3.4.
; M584 X{var.X_MOTOR_DRIVER_F}:{var.X_MOTOR_DRIVER_B}	; Set drive mapping for X
M584 X10.0:10.1	; Set drive mapping for X
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axis X" F{var.CURRENT_FILE} E10555

M584 Y{var.Y_MOTOR_DRIVER}							; Set drive mapping for Y
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axes Y" F{var.CURRENT_FILE} E10556

; Expressions and arrays not supported in 3.4.
;M584 Z{var.Z_MOTOR_DRIVER_L_F}:{var.Z_MOTOR_DRIVER_L_B}:{var.Z_MOTOR_DRIVER_R_F}:{var.Z_MOTOR_DRIVER_R_B}	; Set drive mapping for Z
M584 Z30.0:30.1:31.1:31.0	; Set drive mapping for Z
M98 P"/macros/assert/result.g" R{result} Y"Unable to map the motor drivers to the axes Z" F{var.CURRENT_FILE} E10557

; Microstepping
M350 X{var.X_MICROSTEPPING} I1			; Configure microstepping with interpolation in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in X" F{var.CURRENT_FILE} E10558

M350 Y{var.Y_MICROSTEPPING} I1			; Configure microstepping with interpolation in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in Y" F{var.CURRENT_FILE} E10559

M350 Z{var.Z_MICROSTEPPING} I1			; Configure microstepping with interpolation in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping in Z" F{var.CURRENT_FILE} E10560

; Steps per mm
M92  X{var.X_STEP_MM} 					; Set steps per mm in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in X" F{var.CURRENT_FILE} E10561

M92  Y{var.Y_STEP_MM} 					; Set steps per mm in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in Y" F{var.CURRENT_FILE} E10562

M92  Z{var.Z_STEP_MM}					; Set steps per mm in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm in Z" F{var.CURRENT_FILE} E10563

; Maximum instantaneous speed changes
M566 X{var.X_MAX_SPEED_CHANGE}			; Set maximum instantaneous speed changes in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in X" F{var.CURRENT_FILE} E10564

M566 Y{var.Y_MAX_SPEED_CHANGE}			; Set maximum instantaneous speed changes in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in Y" F{var.CURRENT_FILE} E10565

M566 Z{var.Z_MAX_SPEED_CHANGE}			; Set maximum instantaneous speed changes in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. instantaneous speed changes in Z" F{var.CURRENT_FILE} E10566

; Maximum speeds
M203 X{var.X_MAX_SPEED_MM}				; Set maximum speeds in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in X" F{var.CURRENT_FILE} E10567

M203 Y{var.Y_MAX_SPEED_MM}				; Set maximum speeds in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in Y" F{var.CURRENT_FILE} E10568

M203 Z{var.Z_MAX_SPEED_MM}				; Set maximum speeds in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the max. speeds in Z" F{var.CURRENT_FILE} E10569

; Accelerations
M201 X{var.X_ACCEL} Y{var.Y_ACCEL} Z{var.Z_ACCEL}
M98  P"/macros/assert/result.g" R{result} Y"Unable to set Max Cartesian accelerations" F{var.CURRENT_FILE} E10570
M204 P{var.PRINT_ACCEL} T{var.TRAVEL_ACCEL}
M98  P"/macros/assert/result.g" R{result} Y"Unable to set Accelerations for Print and Travel Moves" F{var.CURRENT_FILE} E10571

; Current and idle factor
M906 X{var.X_MOTOR_CURRENT}						; Set motor currents in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in X driver" F{var.CURRENT_FILE} E10573
M906 Y{var.Y_MOTOR_CURRENT} 					; Set motor currents in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in Y driver" F{var.CURRENT_FILE} E10574
M906 Z{var.Z_MOTOR_CURRENT} 					; Set motor currents in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current in Z driver" F{var.CURRENT_FILE} E10575
M906 I{var.IDLE_FACTOR} T{var.IDLE_TIMEOUT}		; Set idle factor and timeout for the drivers
M98  P"/macros/assert/result.g" R{result} Y"Unable to set the idle factor and timeout for the drivers" F{var.CURRENT_FILE} E10576

; Axis Limits  ----------------------------------------------------------------
M208 X{var.X_AXIS_MIN} 	S{var.AXIS_MINIMUM_PARAMETER}  ; set axis minima in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for X" F{var.CURRENT_FILE} E10577
M208 Y{var.Y_AXIS_MIN} 	S{var.AXIS_MINIMUM_PARAMETER}  ; set axis minima in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Y" F{var.CURRENT_FILE} E10578
M208 Z{var.Z_AXIS_MIN} 	S{var.AXIS_MINIMUM_PARAMETER}  ; set axis minima in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis minimum for Z" F{var.CURRENT_FILE} E10579

M208 X{var.X_AXIS_MAX} 	S{var.AXIS_MAXIMUM_PARAMETER}	; set axis maxima in X
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis maximum for X" F{var.CURRENT_FILE} E10580
M208 Y{var.Y_AXIS_MAX} 	S{var.AXIS_MAXIMUM_PARAMETER}  ; set axis maxima in Y
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis maximum for Y" F{var.CURRENT_FILE} E10581
M208 Z{var.Z_AXIS_MAX} 	S{var.AXIS_MAXIMUM_PARAMETER}  ; set axis maxima in Z
M98  P"/macros/assert/result.g" R{result} Y"Unable to set axis maximum for Z" F{var.CURRENT_FILE} E10582

; Endstops --------------------------------------------------------------------
M574 X{var.X_ENDSTOP_POSITION} S{var.X_ENDSTOP_TYPE} P{var.X_ENDSTOP_PORT} ; configure active-high endstop for low end on X via pins !10.io0.in+!10.io3.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for X" F{var.CURRENT_FILE} E10583

M574 Y{var.Y_ENDSTOP_POSITION} S{var.Y_ENDSTOP_TYPE} P{var.Y_ENDSTOP_PORT} ; configure active-high endstop for low end on Y via pin !25.io0.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for Y" F{var.CURRENT_FILE} E10584

M574 Z{var.Z_ENDSTOP_POSITION} S{var.Z_ENDSTOP_TYPE} P{var.Z_ENDSTOP_PORT} ; configure active-high endstop for high end on Z via pin !30.io0.in+!30.io3.in+!31.io0.in+!31.io3.in
M98  P"/macros/assert/result.g" R{result} Y"Unable to configure the endstop for Z max" F{var.CURRENT_FILE} E10585

; Sensors ---------------------------------------------------------------------
M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.X_MOTOR_DRIVER_F}  A"load_xf_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the X motor board (front)" F{var.CURRENT_FILE} E10587

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.X_MOTOR_DRIVER_B}  A"load_xb_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the X motor board (back)" F{var.CURRENT_FILE} E10588

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.Y_MOTOR_DRIVER}  A"load_y_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the Y motor board" F{var.CURRENT_FILE} E10589

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.Z_MOTOR_DRIVER_L_F}  A"load_zlf_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the Z motor board (left, front)" F{var.CURRENT_FILE} E10590

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.Z_MOTOR_DRIVER_L_B}  A"load_zlb_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the Z motor board (left, back)"  F{var.CURRENT_FILE} E10591

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.Z_MOTOR_DRIVER_R_F}  A"load_zrf_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the Z motor board (right, front)" F{var.CURRENT_FILE} E10592

M98 P"/macros/get_id/sensor.g"
M308 S{global.sensorId}  Y"tmcavg" P{""^var.Z_MOTOR_DRIVER_R_B}  A"load_zrb_avg[]" C100.0
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the load sensor of the Z motor board (right, back)" F{var.CURRENT_FILE} E10593

; Set segmentation to 5 segments/second
M669 S5

; Emergency stop signal -------------------------------------------------------
; Create the input

; Create the trigger event
M581 P{var.EMERGENCY_INPUT_ID} T{var.EMERGENCY_TRIGGER_ID} S1	;Configure the emergency trigger event
M98 P"/macros/assert/result.g" R{result} Y"Unable to create the analog input to trigger event for the emergency" F{var.CURRENT_FILE} E10595

; Creating links:
M98 P"/macros/files/link/create.g" L"/macros/axes/measure_length.g" D"/sys/modules/axes/measure_length.g"
M98 P"/macros/files/link/create.g" L{"/sys/trigger" ^ var.EMERGENCY_TRIGGER_ID ^ ".g"} 	D"/sys/modules/axes/trigger_emergency_probe.g" I{null}

global jobBBOX					= null

; Loading the job bounding box from the last started job if we had a power failure
if (exists(global.powerFailure) && global.powerFailure)
	M98 P"/macros/variable/load.g" N"global.jobBBOX"  ; Will be null if not existing
	M118 S{"[CONFIG] Loaded the previous job bounding box to the global: " ^ global.savedValue}
M400

; CONFIGURATIONS --------------------------------------------------------------
global MODULE_AXES = 0.1	; Setting the current version of this module
M118 S{"[CONFIG] Configured "^var.CURRENT_FILE}
M99							; proper exit
