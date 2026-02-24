; Description: 	
;	This is a HMI command macro to initiate the start.g 
;	Previously the M-code used to initiate the start.g is called via MQTT
;	To make it readable for the MQTT users its better to have macros to call 
;	the M-codes:
;       - this macro is used to call the start.g from the sys folder.
;       - Job file name: J
; Input parameters
;	- J: job file name
;	- U (optional): UUID from the job. If it is omited, it will be 
;					automatically generated.
;	- B (optional): Flag to activate the omit bed leveling, if it is 0 bedleveling
;					is omitted. so default is 1
;	- T (optional): Flag to activate the omit bed touch, if it is 0 bedtouch
;					is omitted. so default is 1
;   - O (optional): job bounding rectangle location and dimensions as vector6. {MINX,MINY,MINZ,MAXX,MAXY,MAXYZ}
;                   used for probing and bed mapping. will be saved as global.jobBBOX
;                   same format as cura output to be consistent.
;	- A (optional): Flag to activate the autoplacement of the print object.(will be far right of the print bed)
;					if it is 1 the autoplacement is active. Default is 0
;	- S (optional): Parameter to shift the part in the print bed. It is an array {Xoffset, Yoffset}
;	- X (optional): Compatible tool number for the current job(extruder number). Only T0 supported.
; Example:
;	M98 P"/macros/hmi/job/start.g" J"/gcodes/_hmi/e3f42d41591e4bcbab7ea20ac0eda02e.gcode" S{108.807,91.5,0.4,141.192,117.874,25.3} A1 B1 T0
; -----------------------------------------------------------------------------
; Mandatory check before starting the file to sync all the input channels
if !inputs[state.thisInput].active
	M99

var CURRENT_FILE = "/macros/hmi/job/start.g"
M118 S{"[start.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
set global.hmiStateDetail = "job_starting"
; Checking global variables and input parameters ------------------------------
; Checking for files first
M98 P"/macros/assert/abort_if_file_missing.g" R{"/sys/start.g"} F{var.CURRENT_FILE} E86400
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/printing/get_ready.g"} F{var.CURRENT_FILE} E86401

; Input parameters 
M98 P"/macros/assert/abort_if.g" R{!exists(param.J)}    Y{"Missing the parameter print file"}    F{var.CURRENT_FILE} E86404
M98 P"/macros/assert/abort_if_null.g" 	R{param.J} Y{"The Jobfile is empty"} F{var.CURRENT_FILE} E86405
M98 P"/macros/assert/abort_if_file_missing.g" R{param.J} F{var.CURRENT_FILE} E86406
M98 P"/macros/assert/abort_if.g" R{(exists(param.B) && (param.B > 1))}    Y{"Invalid value for the param.B "}    F{var.CURRENT_FILE} E86410
M98 P"/macros/assert/abort_if.g" R{(exists(param.T) && (param.T > 1))}    Y{"Invalid value for the param.T "}    F{var.CURRENT_FILE} E86411
M98 P"/macros/assert/abort_if.g" R{(exists(param.O) && (#param.O != 6))}    Y{"param.O must be {MINX,MINY,MINZ,MAXX,MAXY,MAXYZ}"}    F{var.CURRENT_FILE} E86412
M98 P"/macros/assert/abort_if.g" R{(exists(param.S) && (#param.S != 2))}    Y{"param.S must be {X_offset,Y_offset}"}    F{var.CURRENT_FILE} E86414
M98 P"/macros/assert/abort_if.g" R{(exists(param.A) && (param.A > 1))}    Y{"Invalid value for the param.A "}    F{var.CURRENT_FILE} E86415
M98 P"/macros/assert/abort_if.g" R{(exists(param.X) && (param.X < 0 || param.X > 1))}    Y{"Invalid value for the param.X "}    F{var.CURRENT_FILE} E86416
; Definitions -----------------------------------------------------------------
var START_TIME = {+state.time} ; Saving the time in epoch
var START_TIME_STR = {""^var.START_TIME} ; Start time as string
var AUTO_PLACEMENT = (exists(param.A) && (param.A == 1))

; Proceed to start the print ----------------------------------------------------
; Check the machine is in the state to print-----------------------------------
M98 P"/macros/printing/get_ready.g"
;Always set the 2nd coordinate system offset to Zero
G10 L2 P2 X0 Y0
M400
; Creating the UUID -----------------------------------------------------------
M118 S{"[start.g] Creating print UUID"}
if(!exists(global.jobUUID))
	global jobUUID = null
var DEFAULT_UUID = {""^boards[0].uniqueId^"-"^var.START_TIME_STR}
var HAS_USER_UUID = (exists(param.U) && param.U != null && #param.U > 0)
set global.jobUUID = {var.HAS_USER_UUID ? param.U : var.DEFAULT_UUID }
M98 P"/macros/report/event.g" Y{"Job started with jobUUID: %s"} A{global.jobUUID,} F{var.CURRENT_FILE} V86408

; Save the job bounding rectangle ---------------------------------------------
if exists(global.jobBBOX)
	set global.jobBBOX = null
else
	global jobBBOX = null

; flag to know the homing status for print area management
if(!exists(global.homingDone))
	global homingDone = false
else
	set global.homingDone = false
; calculate the length of the print to determine the printable area
var lengthOfPrintInX = 0

if(exists(param.O))
	set global.jobBBOX = param.O
	M118 S{"[start.g] Job Bounding Box available in global.jobBBOX: " ^ global.jobBBOX}
	M98 P"/macros/variable/save_number.g" N"global.jobBBOX" V{global.jobBBOX}
	; check and call the auto placement
	set var.lengthOfPrintInX = global.jobBBOX[3] - global.jobBBOX[0]
	; check if the print fits in the current printable space
	if(global.printingLimitsX[1] >= var.lengthOfPrintInX)
		; check the print is possible in the printable area
		if(!exists(param.S) && !var.AUTO_PLACEMENT && (global.printingLimitsX[1] <= global.jobBBOX[0]))
			M98 P"/macros/assert/abort.g" Y{"Not enough printable area. Please clear print bed before starting new job"} F{var.CURRENT_FILE} E86417
		; check for the autoplacement
		if(var.AUTO_PLACEMENT)			
			M98 P"/macros/job/shift_right.g"
		; check and shift if the shift offset is specified
		if(exists(param.S))
			if(!var.AUTO_PLACEMENT)
				if(param.S[0] != null) && (param.S[1] != null)			
					M98 P"/macros/job/shift_print.g" S{param.S}
					M400
				else
					M98 P"/macros/assert/abort.g" Y{"Invalid shift offset : Aborting the print"} F{var.CURRENT_FILE} E86409
			else
				M98 P"/macros/report/event.g" Y{"Auto placement active: Print will be moved to the Xmax"} F{var.CURRENT_FILE} V86410
	else
		M98 P"/macros/assert/abort.g" Y{"Printable area is not enough for the print"} F{var.CURRENT_FILE} E86408
M400
; Override to compatible extruder------------------------------------------------
if(exists(global.overrideExtruderNum))
	set global.overrideExtruderNum = null
else
	global overrideExtruderNum = null
if(exists(param.X) && (param.X != null))
	set global.overrideExtruderNum = param.X
	
; Omit bed leveling -------------------------------------------------
if(exists(global.omitBedLeveling))
	set global.omitBedLeveling = false
else
	global omitBedLeveling = false

if(exists(param.B) && (param.B == 0))
	set global.omitBedLeveling = true
	M118 S{"Omitting bed leveling"}

; Omit bedtouch------------------------------------------------------------------
if(exists(global.omitBedTouch))
	set global.omitBedTouch = false
else
	global omitBedTouch = false

if(exists(param.T) && (param.T == 0))
	set global.omitBedTouch = true
; Let's start the print ---------------------------------------------------------
M32 {param.J}	;Select the job file and Start the SD print
M400
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}

; -------------------------------------------------------------------------------
M118 S{"[start.g] Done "^var.CURRENT_FILE}
M99		;Proper file exit