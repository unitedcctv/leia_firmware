; Description: 	
;   The bed mesh compensation will be performed.
; Output parameters:
;	- global.bedFile: Result file
;------------------------------------------------------------------------------
var CURRENT_FILE 	= "/macros/probe/bed.g"
M118 S{"[bed.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Set global return variables -------------------------------------------------
if (!exists(global.bedFile))
	global bedFile = null
else 
	set global.bedFile = null

; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/probe/measure_at_same_z.g"} F{var.CURRENT_FILE} E65000
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{!exists(heat.bedHeaters[0])}  					Y{"Missing heat.bedHeaters"}  								F{var.CURRENT_FILE} E65011
M98 P"/macros/assert/abort_if_null.g" R{heat.bedHeaters[0]} 						Y{"Unexpected null in heat.bedHeaters[0]"}  				F{var.CURRENT_FILE} E65012
M98 P"/macros/assert/abort_if.g" R{!exists(heat.heaters[heat.bedHeaters[0]].max)}	Y{"Missing heat.heaters[heat.bedHeaters[0]]"}  				F{var.CURRENT_FILE} E65013
M98 P"/macros/assert/abort_if.g" R{!exists(move.compensation.probeGrid.maxs)}  		Y{"Missing move.compensation.probeGrid.maxs. Use M557 for it."}  F{var.CURRENT_FILE} E65014
M98 P"/macros/assert/abort_if.g" R{!exists(move.compensation.probeGrid.mins)}  		Y{"Missing move.compensation.probeGrid.mins. Use M557 for it."}  F{var.CURRENT_FILE} E65015
M98 P"/macros/assert/abort_if.g" R{!exists(move.compensation.probeGrid.spacings)}  	Y{"Missing move.compensation.probeGrid.spacings. Use M557 for it."}  F{var.CURRENT_FILE} E65016
M98 P"/macros/assert/abort_if_null.g" R{move.compensation.probeGrid.maxs} 			Y{"Unexpected null in probeGrid.maxs"}  					F{var.CURRENT_FILE} E65017
M98 P"/macros/assert/abort_if_null.g" R{move.compensation.probeGrid.mins} 			Y{"Unexpected null in probeGrid.mins"}  					F{var.CURRENT_FILE} E65018
M98 P"/macros/assert/abort_if_null.g" R{move.compensation.probeGrid.spacings} 		Y{"Unexpected null in probeGrid.spacings"} 					F{var.CURRENT_FILE} E65019
; Check machine conditions
var IS_NOT_HOMED = (!move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed || (exists(move.axes[3].homed) && !move.axes[3].homed) || (exists(move.axes[4].homed) && !move.axes[4].homed) )
M98 P"/macros/assert/abort_if.g" R{var.IS_NOT_HOMED}  Y{"Home required before running bed mesh"}  F{var.CURRENT_FILE} E65030

; Definitions -----------------------------------------------------------------
; Getting the temperature of the bed from the object model
var BED_HEATER_ID	 	= heat.bedHeaters[0]			; Get the bed heater ID
var BED_TEMP 		 	= floor(heat.heaters[var.BED_HEATER_ID].active) ; Current bed temperature.

; Use Job UUID as file name if available
var BEDMAP_ID = +state.time
if(exists(global.jobUUID) && global.jobUUID != null && #global.jobUUID == 32)
	set var.BEDMAP_ID = global.jobUUID

var BEDMAPS_FOLDER 	 	= "/sys/bedmaps/"				; Folder to record all the bedmaps
var BEDMAP_FILE_NAME 	= {var.BEDMAP_ID^".csv"} ; New file name
var BEDMAP_FILE_PATH 	= {var.BEDMAPS_FOLDER^var.BEDMAP_FILE_NAME} ; Full path of the file to save
var BEDMAP_NAME_DEFAULT = "/sys/heightmap.csv" 			; Default File name

var MARGINS 			= 10							; [mm] Margins of the bed leveling
var X_START				= move.compensation.probeGrid.mins[0] ; [mm] Minimum position in X
var X_END				= move.compensation.probeGrid.maxs[0] ; [mm] Maximum position in X
var X_AMOUNT_POINTS 	= floor((var.X_END - var.X_START)/move.compensation.probeGrid.spacings[0]) + 2; [] Amount of points in X
var Y_START				= move.compensation.probeGrid.mins[1] ; [mm] Minimum position in Y
var Y_END				= move.compensation.probeGrid.maxs[1] ; [mm] Maximum position in Y
var Y_AMOUNT_POINTS 	= floor((var.Y_END - var.Y_START)/move.compensation.probeGrid.spacings[1]) + 2; [] Amount of points in Y
var DEVIATION_WARNING 	= 0.3							; [mm] Deviation warning
var DEVIATION_ERROR 	= 1								; [mm] Deviation error
var Z_BACKLASH          = 0.5

var Z_FINAL_POSITION 	= 5							; [mm] Final position in Z

var MOVE_SPEED 			= 20000							; [mm/min] Speed to move between steps
var MAX_CHANGE_IN_Z_NEXT_POINT = 0.5					; [mm] Max change in Z when using measure_at_target_value.g

var CSV_DELIMITER		= ","							; Default CSV delimiter

var X_STEP_SIZE = (var.X_END-var.X_START) / (var.X_AMOUNT_POINTS-1) ; [mm] Size of the step in X
var Y_STEP_SIZE = (var.Y_END-var.Y_START) / (var.Y_AMOUNT_POINTS-1) ; [mm] Size of the step in Y

; Fire event to initialize bed map in HMI
; Example: "#V65010# ~X:-45.0mm,1000.0mm,10|Y:0.0mm,500.0mm,7~ | In file /macros/probe/bed.g"
M98 P"/macros/report/event.g" Y{"~X:"^var.X_START^"mm,"^var.X_END^"mm,"^var.X_AMOUNT_POINTS^"|Y:"^var.Y_START^"mm,"^var.Y_END^"mm,"^var.Y_AMOUNT_POINTS^"~"}  F{var.CURRENT_FILE} V65010
; Deselecting extruder --------------------------------------------------------
T-1
M400
; Creating the headers of the files -------------------------------------------
var HEADER_LINE_1 = "RepRapFirmware height map file v2 generated at "^{+state.time}^", min error 0.0, max error 0.0, mean 0.0, deviation 0.0, temperature "^var.BED_TEMP
var HEADER_LINE_2 = "axis0,axis1,min0,max0,min1,max1,radius,spacing0,spacing1,num0,num1"
var HEADER_LINE_3 = "X,Y,"^{var.X_START}^","^{var.X_END}^","^{var.Y_START}^","^{var.Y_END}^",-1,"^{var.X_STEP_SIZE}^","^{var.Y_STEP_SIZE}^","^{var.X_AMOUNT_POINTS}^","^{var.Y_AMOUNT_POINTS}

echo  >{var.BEDMAP_FILE_PATH}	  {var.HEADER_LINE_1}
echo  >{var.BEDMAP_NAME_DEFAULT } {var.HEADER_LINE_1}
echo >>{var.BEDMAP_FILE_PATH}	  {var.HEADER_LINE_2}
echo >>{var.BEDMAP_NAME_DEFAULT } {var.HEADER_LINE_2}
echo >>{var.BEDMAP_FILE_PATH}	  {var.HEADER_LINE_3}
echo >>{var.BEDMAP_NAME_DEFAULT } {var.HEADER_LINE_3}

G29 S2			; Disable mesh compensation

; Moving to the first point ---------------------------------------------------
var Z_START_POINT = global.PROBE_OFFSET_Z
M118 S{"[bed.g] Moving to the start position X"^var.X_START^" Y"^var.Y_START^" Z"^var.Z_START_POINT}
G1 X{var.X_START} Y{var.Y_START} F{var.MOVE_SPEED}
M400
G1 Z{var.Z_START_POINT-var.Z_BACKLASH}
G1 Z{var.Z_START_POINT}
M400
G4 S2 ; wait a bit for stabilization
M400

; Start the scan --------------------------------------------------------------
M118 S{"[bed.g] Start measuring the points"}
var measuredValues 		= vector(var.X_AMOUNT_POINTS, 0)	; Values of each line will be recorded here.
var moveDirection 		= 1 	; Variable use to scan the bed doing a zig-zag. 1: Move positive | -1: Move negative
var yPointsCounter 		= 0		; Counter used to track the Y rows
var firstPointOffset 	= 0		; [mm] Offset of the first point measured. It will be obtained in the loop.
while (var.yPointsCounter < var.Y_AMOUNT_POINTS)
	var xPointsCounter = 0		; Counter used to track the X columns
	; Constant position of Y in this line.
	var Y_POSITION = var.Y_START+(var.yPointsCounter*var.Y_STEP_SIZE) ; Position related to current row
	while (var.xPointsCounter < var.X_AMOUNT_POINTS) ; Start scannig the line with constant Y (same row)
		M98 P"/macros/printing/abort_if_forced.g" Y{"In bed mapping scan loop"} F{var.CURRENT_FILE} L{inputs[state.thisInput].lineNumber}
		; Obtaining the position in X (based on the column)
		var xPosition = var.xPointsCounter*var.X_STEP_SIZE ; First calculate the relative position
		set var.xPosition = { (var.moveDirection == 1) ? (var.X_START + var.xPosition) : (var.X_END - var.xPosition) }
		; If it is not the first point we move in Z:
		G1 X{var.xPosition} Y{var.Y_POSITION} F{var.MOVE_SPEED}
		M400
		;G4 S0.5
		M98 P"/macros/probe/get_sample_single_z.g"
		M400
		; Save the value in the array
		var MEASURED_INDEX = { (var.moveDirection == 1) ? (var.xPointsCounter) : (var.X_AMOUNT_POINTS-var.xPointsCounter-1) }
		; invert value to get bed position at point
		var HEIGHT_VALUE = -global.probeMeasuredValue

		; Reporting the value for HMI to display
		; Example: "#V65010# ~X:8|Y:6|VAL:-0.5986073~ | In file /macros/probe/bed.g"
		M98 P"/macros/report/event.g" Y{"~X:"^var.MEASURED_INDEX^"|Y:"^var.yPointsCounter^"|VAL:"^var.HEIGHT_VALUE^"mm~"}  F{var.CURRENT_FILE} V65011
		; check deviation and warn or abort
		if abs(var.HEIGHT_VALUE) > var.DEVIATION_ERROR
			M472 P{var.BEDMAP_NAME_DEFAULT} ; delete bedmap file
			M98 P"/macros/assert/abort.g" Y{"Printbed out of tolerance (%smm) at X:%s,Y:%s. Please level the Printbed"} A{var.HEIGHT_VALUE,floor(var.xPosition),floor(var.Y_POSITION)} F{var.CURRENT_FILE} E65010
		elif abs(var.HEIGHT_VALUE) > var.DEVIATION_WARNING
			M98 P"/macros/report/warning.g" Y{"Printbed uneven (%smm) at X:%s,Y:%s"} A{var.HEIGHT_VALUE,floor(var.xPosition),floor(var.Y_POSITION)} F{var.CURRENT_FILE} W65011
		M400

		set var.measuredValues[var.MEASURED_INDEX] = var.HEIGHT_VALUE

		; Move to the next point
		set var.xPointsCounter = var.xPointsCounter + 1

	M400
	; Change direction of the move
	set var.moveDirection = -var.moveDirection 

	; Writing the file with the proper information
	set var.xPointsCounter = 0
	while (var.xPointsCounter < (var.X_AMOUNT_POINTS-1))
		echo >>>{var.BEDMAP_FILE_PATH}	 	{var.measuredValues[var.xPointsCounter]^var.CSV_DELIMITER}
		echo >>>{var.BEDMAP_NAME_DEFAULT}  	{var.measuredValues[var.xPointsCounter]^var.CSV_DELIMITER}
		set var.xPointsCounter = var.xPointsCounter + 1
	echo >>{var.BEDMAP_FILE_PATH}	  		{var.measuredValues[var.xPointsCounter]}
	echo >>{var.BEDMAP_NAME_DEFAULT}  		{var.measuredValues[var.xPointsCounter]}
	; Next line
	set var.yPointsCounter = var.yPointsCounter + 1

M400
; Return the bed mapping file -------------------------------------------------
set global.bedFile = var.BEDMAP_FILE_PATH
M118 S{"[bed.g] File Created: "^var.BEDMAP_FILE_PATH}
M118 S{"[bed.g] Overwriting file: "^var.BEDMAP_NAME_DEFAULT}

; -----------------------------------------------------------------------------
M118 S{"[bed.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit