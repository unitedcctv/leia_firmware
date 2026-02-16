;---------------------------------------------------------------------------------------------
;	This macro is used to identify the main natural frequencies and the damping ratios of the machine.
;   The procedure moves the motors by one full-step to aproximate as much as possible an impulse force.
;   The impulses are repeated to be individually analized and have a statistical estimation of the results.
;   The analysis is done for the X and Y axis, individually and combined.
;   
;---------------------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/input_shaping/system_identification.g"
M118 S{"[system_identification.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Check machine conditions
var IS_NOT_HOMED = (!move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed )
M98 P"/macros/assert/abort_if.g" R{var.IS_NOT_HOMED}  Y{"Home required before running system identification"}  F{var.CURRENT_FILE} E88100

; Definitions
var X_POS        			= (move.axes[0].max + move.axes[0].min)/2        									; [mm] X-axis center position
var Y_POS        			= (move.axes[1].max + move.axes[1].min)/2 - 5    									; [mm] Y-axis center position - half distance between extruders
var Z_POS        			= 5            																		; [mm] Z-axis position
var N_STEPS      			= 5           																		; Number of impulse responses
var T0_CAN_ACC		 		= {20, 20.0}         																; {CAN-ID, Accelerometer port} of T0 extruder board
var T1_CAN_ACC 				= {21, 21.0}         																; {CAN-ID, Accelerometer port} of T1 extruder board
var T_RELAX		 			= 0.5																				; [s] Relax time after one motor's step
var T_STEP	     			= 0.15 + var.T_RELAX																; [s] Approximate time duration of one impulse response
var SAMP_FREQ	 			= 400																				; [Hz] Accelerometer's sampling frequency
var N_SAMPLES    			= ceil(var.T_STEP * var.SAMP_FREQ * var.N_STEPS + var.T_RELAX * var.SAMP_FREQ)   	; Number of samples the accelerometer has to log
var DIST_STEP				= 0.5																				; [mm] Distance for one impulse step
var MAX_SPEED 				= min(move.axes[0].speed, move.axes[1].speed) 										; [mm/min] Impulse target speed
var MAX_ACC   				= min(move.axes[0].acceleration, move.axes[1].acceleration)							; [mm/sec^2] Impulse acceleration
; Save settings
var TRAV_ACC  = move.travelAcceleration
var IS_TYPE   = move.shaping.type
var IS_FREQ   = move.shaping.frequency
var IS_DAMP   = move.shaping.damping

; Define folder where to save raw data and report, use jobUUID if available otherwise use timestamp
var FOLDER_ID = null
if(exists(global.jobUUID) && global.jobUUID != null && #global.jobUUID == 32)
	set var.FOLDER_ID = {global.jobUUID}
else
	set var.FOLDER_ID = {+state.time}

if(!exists(global.sysidReportID))
	global sysidReportID = null
set global.sysidReportID = "/sys/accelerometer/"^var.FOLDER_ID^"/"

; Check for installed Extruders, use the first one found
var numExtrudersInstalled = 0
var boardAccID = null
var cpuFanID = null
while iterations < #boards
	if boards[iterations].canAddress == var.T0_CAN_ACC[0]
		set var.numExtrudersInstalled = var.numExtrudersInstalled + 1
		set var.boardAccID = var.T0_CAN_ACC[1]
		set var.cpuFanID = exists(global.cpuFanId) ? global.cpuFanId[0] : null
		continue

	if boards[iterations].canAddress == var.T1_CAN_ACC[0]
		set var.numExtrudersInstalled = var.numExtrudersInstalled + 1
		set var.boardAccID = (var.boardAccID == null) ? var.T1_CAN_ACC[1] : var.boardAccID
		set var.cpuFanID = (exists(global.cpuFanId) && var.cpuFanID == null) ? global.cpuFanId[1] : var.cpuFanID
		continue

if var.boardAccID == null
	M118 S{"[system_identification.g] No candidate boards found, skipping."}
	M118 S{"[system_identification.g] Done "^var.CURRENT_FILE}
	M99

set global.hmiStateDetail = "job_calib_shaky"

; Setup
G1 X{var.X_POS} Y{var.Y_POS} Z{var.Z_POS} F12000		; Move to desired position
M955 P{var.boardAccID} S{var.SAMP_FREQ} I41 	    	; Define accelerometer orientation and sampling frequency to 400 Hz
G91						                            	; Relative coordinates
if (var.cpuFanID != null)
	M106 P{var.cpuFanID} S0     			    		; Turn-off fan in front of extruder board to reduce accelerometer noise
	G4 S5												; Wait for the fan to poweroff
M593 P"none"											; Disable Input Shaping
M204 T{var.MAX_ACC}										; Increase acceleration

; Identification moves                            
M956 P{var.boardAccID} S{var.N_SAMPLES} A0 F{var.FOLDER_ID^"/sysid_X.csv"}   	; Do N_STEPS in X direction and save accelerometer data
G4 S{var.T_RELAX}
while (iterations < var.N_STEPS)                   
	G1 X{var.DIST_STEP} F{var.MAX_SPEED}
	G4 S{var.T_RELAX}

G4 S2 		                                            						; Wait to be sure the accelerometer stops to log
M956 P{var.boardAccID} S{var.N_SAMPLES} A0 F{var.FOLDER_ID^"/sysid_Y.csv"}   	; Do N_STEPS in Y direction and save accelerometer data
G4 S{var.T_RELAX}
while (iterations < var.N_STEPS)
	G1 Y{var.DIST_STEP} F{var.MAX_SPEED}
	G4 S{var.T_RELAX}

G4 S2                                               							; Wait to be sure the accelerometer stops to log
M956 P{var.boardAccID} S{var.N_SAMPLES} A0 F{var.FOLDER_ID^"/sysid_XY.csv"}  	; Do N_STEPS in XY direction to return to the start position and save accelerometer data
G4 S{var.T_RELAX}
while (iterations < var.N_STEPS)
	G1 X{-var.DIST_STEP} Y{-var.DIST_STEP} F{var.MAX_SPEED}
	G4 S{var.T_RELAX}

; Restore configurations 
M593 P{var.IS_TYPE} F{var.IS_FREQ} S{var.IS_DAMP}				; Restore Input Shaping
M204 T{var.TRAV_ACC}											; Restore travel acceleration
if (var.cpuFanID != null)
	M106 P{var.cpuFanID} S1     								; Turn on fan

; Do System Identification
M98 P"/macros/assert/abort_if_file_missing.g" R{global.sysidReportID^"sysid_X.csv"}  F{var.CURRENT_FILE} E88102
M98 P"/macros/assert/abort_if_file_missing.g" R{global.sysidReportID^"sysid_Y.csv"}  F{var.CURRENT_FILE} E88103
M98 P"/macros/assert/abort_if_file_missing.g" R{global.sysidReportID^"sysid_XY.csv"} F{var.CURRENT_FILE} E88104

M118 S{"[system_identification.g] Calling HMI-Server to run the system identification for measurement: "^global.sysidReportID}
M98 P"/macros/python/call_function.g" N"SYSTEM_IDENTIFICATION" F{global.sysidReportID} A{"{''fs'':"^var.SAMP_FREQ^",''nsteps'':"^var.N_STEPS^",''report_folder'':'"^global.sysidReportID^"',''peak_thrs'':"^global.SYSID_PEAK_THRS^"}"}
M98 P"/macros/assert/abort_if.g" R{!exists(global.pythonResult)} Y{"Missing required global pythonResult"}  F{var.CURRENT_FILE} E88105
M98 P"/macros/assert/abort_if_null.g" R{global.pythonResult}  	 Y{"No answer from Python"} 				F{var.CURRENT_FILE} E88106

if (!fileexists(global.sysidReportID^"report.txt"))
	M118 S{"[system_identification.g] Report file not generated."}
else
	; Write metadata to report
	echo >>{global.sysidReportID^"report.txt"} {""}
	echo >>{global.sysidReportID^"report.txt"} {"num_tools,board_used,"^var.numExtrudersInstalled^","^var.boardAccID}
M400

M118 S{"[system_identification.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit
