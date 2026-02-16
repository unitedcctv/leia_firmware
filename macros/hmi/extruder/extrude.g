; Description:
;   This is a HMI command macro to initiate the extrude functionality. The 
;	current selected tool will be used to extrude.
; Input Parameters:
;	- F : [mm/s] Feedrate
;	- E : [mm] length of filament to extrude
;   - T (optional) : tool index
; Example:
;	M98 P"/macros/hmi/extruder/extrude.g" F{1.0} E{200.0}
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/hmi/extruder/extrude.g"
M118 S{"[extrude.g] Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}
; Check files
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/emergency/is_ready_to_operate.g"} 	F{var.CURRENT_FILE} E84000
; Checking global variables and input parameters ------------------------------
;M98 P"/macros/emergency/is_ready_to_operate.g"
; Checking global variables
M98 P"/macros/assert/abort_if.g" R{state.currentTool == 0 && !exists(global.MODULE_EXTRUDER_0)} Y{"Missing module EXTRUDER 0"} F{var.CURRENT_FILE} E84001
M98 P"/macros/assert/abort_if.g" R{state.currentTool == 1 && !exists(global.MODULE_EXTRUDER_1)} Y{"Missing module EXTRUDER 1"} F{var.CURRENT_FILE} E84002
; Check that parameters are present and not null
M98 P"/macros/assert/abort_if.g"		R{!exists(param.E)}     	Y{"Missing extrusion length param E"}    F{var.CURRENT_FILE} E84003
M98 P"/macros/assert/abort_if_null.g" 	R{param.E}              	Y{"Extrusion length param E is null"} F{var.CURRENT_FILE} E84004
M98 P"/macros/assert/abort_if.g"        R{!exists(param.F)}			Y{"Missing Feedrate param F"}    F{var.CURRENT_FILE} E84005
M98 P"/macros/assert/abort_if_null.g" 	R{param.F}					Y{"Feedrate param F is null"} F{var.CURRENT_FILE} E84006
M98 P"/macros/assert/abort_if.g" 	R{param.F == 0}					Y{"Feedrate is 0"} F{var.CURRENT_FILE} E84007

; select tool
if (exists(param.T))
	M98 P"/macros/assert/abort_if.g" R{(!exists(tools[param.T]))} Y{"Tool param T=%s outside range of available tools %s"} A{param.T,#tools}    F{var.CURRENT_FILE} E84008
	if(param.T != state.currentTool)
		T{param.T}
else
	M98 P"/macros/assert/abort_if.g" R{state.currentTool == -1} Y{"No tool selected and no param T provided"}    F{var.CURRENT_FILE} E84009

M400

; Definitions------------------------------------------------------------------
var MAX_EX 			= 2000 			; [mm]
var MIN_EX 			= -2000 		; [mm]
var MIN_F  			= -50			; [mm/s]
var MAX_F  			= 30			; [mm/s]
var FEEDRATE_MM_MIN = {param.F * 60} ; [mm/min] Conversion to mm/min from mm/sec
; Check set temperature
var TOOL_TEMP = tools[state.currentTool].active[0]
var MIN_EX_TEMP = heat.coldExtrudeTemperature
var MIN_RETR_TEMP = heat.coldRetractTemperature

; Check the ranges ------------------------------------------------------------
M98 P"/macros/assert/abort_if.g"		R{(param.E)< var.MIN_EX}	Y{"Extrusion length param E=%s is smaller than min %s"} A{param.E,var.MIN_EX} F{var.CURRENT_FILE} E84010
M98 P"/macros/assert/abort_if.g"		R{(param.E)> var.MAX_EX}	Y{"Extrusion length param E=%s is greater than max %s"} A{param.E ,var.MAX_EX} F{var.CURRENT_FILE} E84011
M98 P"/macros/assert/abort_if.g"		R{(param.F)< var.MIN_F}		Y{"Feedrate param F=%s is smaller than min %s"} A{param.F, var.MIN_F} F{var.CURRENT_FILE} E84012
M98 P"/macros/assert/abort_if.g"		R{(param.F)> var.MAX_F}		Y{"Feedrate param F=%s is greater than max %s"} A{param.F,var.MAX_F} F{var.CURRENT_FILE} E84013
if(param.E < 0)
	M98 P"/macros/assert/abort_if.g"		R{var.TOOL_TEMP < var.MIN_RETR_TEMP}	Y{"Set temperature %s is smaller than min. retraction temp %s"} A{var.TOOL_TEMP,var.MIN_RETR_TEMP} F{var.CURRENT_FILE} E84014

if(param.E > 0)
	M98 P"/macros/assert/abort_if.g"		R{var.TOOL_TEMP < var.MIN_EX_TEMP}	Y{"Set temperature %s is smaller than min. extrusion temp %s"} A{var.TOOL_TEMP,var.MIN_EX_TEMP} F{var.CURRENT_FILE} E84015

var calculatedExtrLength = param.E	; variable to store the extrusion length
;Proceed with the extrusion------------------------------------------------------
; Loading the flow rate multiplier if exists
if(exists(global.flowRateMultipliers) && (global.flowRateMultipliers[param.T] != null))	
	set var.calculatedExtrLength = (global.flowRateMultipliers[param.T] * param.E) / 100

; set relative extrusion mode
M83
M98 P"/macros/report/event.g" Y{"Starting extrude %smm with %smm/s"} A{param.E,param.F} F{var.CURRENT_FILE} V84000

G1 E{var.calculatedExtrLength} F{var.FEEDRATE_MM_MIN}
M400

M98 P"/macros/assert/result.g" R{result} Y"Unable to extrude" F{var.CURRENT_FILE} E84016
M400
M98 P"/macros/report/event.g" Y{"Done extruding"} F{var.CURRENT_FILE} V84001
; Checking the Call Id param for HMI
if exists(param.I)
	M118 S{"#I"^param.I^"#DONE"}
;--------------------------------------------------------------------------------------------------------
M118 S{"extrude.g] Done "^var.CURRENT_FILE}
M99 ; Proper exit