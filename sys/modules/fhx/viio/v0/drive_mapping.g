; Description: 	
;	This will set drive mapping for FHX
; Example:
;	M98 P"/sys/modules/fhx/viio/v0/drive_mapping.g"
;------------------------------------------------------------------------------
var CURRENT_FILE = "/sys/modules/fhx/viio/v0/drive_mapping.g"
M118 S{"[DRIVE MAPPING]  Starting "^var.CURRENT_FILE^" I:"^state.thisInput^" S:"^inputs[state.thisInput].stackDepth}

; Checking for files first ----------------------------------------------------------------------------------
M98 P"/macros/assert/abort_if_file_missing.g" R{"/macros/fhx/control/mixratio.g"} F{var.CURRENT_FILE} E17611

; Offsets
var OFFSET_X_DEFAULT 	= {-8.35,-8.35}		; [mm] Default offset in X for T0 and T1
var OFFSET_Y_DEFAULT 	= {-48.9, 47.1}		; [mm] Default offset in Y for T0 and T1

; global.FHX_ENABLED[0][0] = var.HAS_EXTRUDER_0
; global.FHX_ENABLED[1][0] = var.HAS_EXTRUDER_1
var T0_IDX = { global.FHX_ENABLED[0][0] ? tools[0].extruders[0] : null } 
var T1_IDX = { global.FHX_ENABLED[1][0] ? tools[1].extruders[0] : null } 

; Configuration values --------------------------------------------------------
var MSTEP       = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].microstepping.value 	: null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].microstepping.value   : null } }
var STEPS       = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].stepsPerMm 			    : null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].stepsPerMm            : null } }
var JERKS       = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].jerk 					: null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].jerk                  : null } }
var SPEEDS      = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].speed 				    : null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].speed                 : null } }
var ACC         = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].acceleration 			: null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].acceleration 		    : null } }
var CURR        = { { global.FHX_ENABLED[0][0] ? move.extruders[var.T0_IDX].current 			  	: null }, { global.FHX_ENABLED[1][0] ? move.extruders[var.T1_IDX].current 		    : null } }
var PRESSURE_ADVANCE_FHX = 0.07	; [sec] Pressure advance to use in the extruders (M572)

; Setting the driver settings
if ((global.FHX_ENABLED[0][1]) && (global.FHX_ENABLED[1][1])) 
	; Microstepping
	M350 E{var.MSTEP[0],var.MSTEP[1],var.MSTEP[0],var.MSTEP[0],var.MSTEP[1],var.MSTEP[1]}         
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping with infinity box" F{var.CURRENT_FILE} E17613            
	; Steps per mm
	M92  E{var.STEPS[0],var.STEPS[1],var.STEPS[0],var.STEPS[0],var.STEPS[1],var.STEPS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm with  infinity box" F{var.CURRENT_FILE} E17614
	; Maximum instantaneous speed changes
	M566 E{var.JERKS[0],var.JERKS[1],var.JERKS[0],var.JERKS[0],var.JERKS[1],var.JERKS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk with infinity box" F{var.CURRENT_FILE} E17615
	; Maximum speeds
	M203 E{var.SPEEDS[0],var.SPEEDS[1],var.SPEEDS[0],var.SPEEDS[0],var.SPEEDS[1],var.SPEEDS[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the speed with infinity box" F{var.CURRENT_FILE} E17616
	; ACC
	M201 E{var.ACC[0],var.ACC[1],var.ACC[0],var.ACC[0],var.ACC[1],var.ACC[1]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the acceleration with infinity box" F{var.CURRENT_FILE} E17617
	; Current and idle factor
	M906 E{var.CURR[0],var.CURR[1],var.CURR[0],var.CURR[0],var.CURR[1],var.CURR[1]} I{move.idle.factor*100} ; [mA][%] Set motor CURR and motor idle factor in per cent in X
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current with infinity box" F{var.CURRENT_FILE} E17618
	; Redifine the tools
	M563 P0 D0:2:3 H{tools[0].heaters[0]} F{tools[0].fans[0]} S{tools[0].name} ; ReDefine tool
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine T0" F{var.CURRENT_FILE} E17619
	M563 P1 D1:4:5 H{tools[1].heaters[0]} F{tools[1].fans[0]} S{tools[1].name} ; ReDefine tool
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine T1" F{var.CURRENT_FILE} E17620
	; Setting the mix ratios 
	M98  P"/macros/fhx/control/mixratio.g" T0
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the mix ratio with infinity box T0" F{var.CURRENT_FILE} E17621
	M98  P"/macros/fhx/control/mixratio.g" T1
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the mix ratio with infinity box T1" F{var.CURRENT_FILE} E17622
	; Pressure advance
	M572 D0:1:2:3:4:5 S{var.PRESSURE_ADVANCE_FHX}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the pressure advance with infinity box" F{var.CURRENT_FILE} E17623
	; Tool position
	M98 P"/sys/modules/extruders/basic/set_offset.g" T0 X{var.OFFSET_X_DEFAULT[0]}  Y{var.OFFSET_Y_DEFAULT[0]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the offset with infinity box T0" F{var.CURRENT_FILE} E17624
	M98 P"/sys/modules/extruders/basic/set_offset.g" T1 X{var.OFFSET_X_DEFAULT[1]}  Y{var.OFFSET_Y_DEFAULT[1]}  
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the offset with infinity box T1" F{var.CURRENT_FILE} E17625  
elif ((global.FHX_ENABLED[param.T][1]) && (!global.FHX_ENABLED[1 - param.T][1]))
	; Microstepping
	M350 E{var.MSTEP[param.T],var.MSTEP[param.T],var.MSTEP[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping with infinity box" F{var.CURRENT_FILE} E17628     
	; Steps per mm
	M92  E{var.STEPS[param.T],var.STEPS[param.T],var.STEPS[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm with infinity box" F{var.CURRENT_FILE} E17629
	; Maximum instantaneous speed changes
	M566 E{var.JERKS[param.T],var.JERKS[param.T],var.JERKS[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk with infinity box" F{var.CURRENT_FILE} E17630
	; Maximum speeds
	M203 E{var.SPEEDS[param.T],var.SPEEDS[param.T],var.SPEEDS[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the speed with infinity box" F{var.CURRENT_FILE} E17631
	; ACC
	M201 E{var.ACC[param.T],var.ACC[param.T],var.ACC[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the acceleration with infinity box" F{var.CURRENT_FILE} E17632
	; Current and idle factor
	M906 E{var.CURR[param.T],var.CURR[param.T],var.CURR[param.T]} I{move.idle.factor*100} ; [mA][%] Set motor CURR and motor idle factor in per cent in X
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current with infinity box" F{var.CURRENT_FILE} E17633
	; Redifine the tools
	M563 P{param.T} D0:1:2 H{tools[param.T].heaters[0]} F{tools[param.T].fans[0]} S{tools[param.T].name} ; ReDefine tool
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine" F{var.CURRENT_FILE} E17634
	; Setting the mix ratios
	M98  P"/macros/fhx/control/mixratio.g" T{param.T}
	; Pressure advance
	M572 D0:1:2 S{var.PRESSURE_ADVANCE_FHX}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the pressure advance with infinity box" F{var.CURRENT_FILE} E17635
	; Tool position
	M98 P"/sys/modules/extruders/basic/set_offset.g" T{param.T} X{var.OFFSET_X_DEFAULT[param.T]}  Y{var.OFFSET_Y_DEFAULT[param.T]}
	M98  P"/macros/assert/result.g" R{result} Y"Unable to set the offset with infinity box" F{var.CURRENT_FILE} E17636
	if (global.FHX_ENABLED[1 - param.T][0]) 
		; Microstepping
		M350 E{var.MSTEP[1-param.T],var.MSTEP[param.T],var.MSTEP[param.T],var.MSTEP[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the microstepping with infinity box" F{var.CURRENT_FILE} E17652     
		; Steps per mm
		M92  E{var.STEPS[1 - param.T],var.STEPS[param.T],var.STEPS[param.T],var.STEPS[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the steps per mm with infinity box" F{var.CURRENT_FILE} E17653
		; Maximum instantaneous speed changes
		M566 E{var.JERKS[1 - param.T],var.JERKS[param.T],var.JERKS[param.T],var.JERKS[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the jerk with infinity box" F{var.CURRENT_FILE} E17654
		; Maximum speeds
		M203 E{var.SPEEDS[1 - param.T],var.SPEEDS[param.T],var.SPEEDS[param.T],var.SPEEDS[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the speed with infinity box" F{var.CURRENT_FILE} E17655
		; ACC
		M201 E{var.ACC[1 - param.T],var.ACC[param.T],var.ACC[param.T],var.ACC[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the acceleration with infinity box" F{var.CURRENT_FILE} E1756
		; Current and idle factor
		M906 E{var.CURR[1 - param.T]}{var.CURR[param.T],var.CURR[param.T],var.CURR[param.T]} I{move.idle.factor*100} ; [mA][%] Set motor CURR and motor idle factor in per cent in X
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the current with infinity box" F{var.CURRENT_FILE} E17657
		; Redifine the tools
		M563 P{param.T} D1:2:3 H{tools[param.T].heaters[0]} F{tools[param.T].fans[0]} S{tools[param.T].name} ; ReDefine tool
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine" F{var.CURRENT_FILE} E17658
		M563 P{1 - param.T} D0 H{tools[1 - param.T].heaters[0]} F{tools[1 - param.T].fans[0]} S{tools[1 - param.T].name} ; ReDefine tool
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the redefine T1" F{var.CURRENT_FILE} E17659
		; Setting the mix ratios
		M98  P"/macros/fhx/control/mixratio.g" T{param.T}
		; Pressure advance
		M572 D0:1:2:3 S{var.PRESSURE_ADVANCE_FHX}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the pressure advance with infinity box" F{var.CURRENT_FILE} E17664
		; Tool position
		M98 P"/sys/modules/extruders/basic/set_offset.g" T{param.T} X{var.OFFSET_X_DEFAULT[param.T]}  Y{var.OFFSET_Y_DEFAULT[param.T]}
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the offset with infinity box" F{var.CURRENT_FILE} E17661
		M98 P"/sys/modules/extruders/basic/set_offset.g" T{1 - param.T} X{var.OFFSET_X_DEFAULT[1 - param.T]}  Y{var.OFFSET_Y_DEFAULT[1 - param.T]}  
		M98  P"/macros/assert/result.g" R{result} Y"Unable to set the offset with infinity box" F{var.CURRENT_FILE} E17662
;-----------------------------------------------------------------------
M118 S{"[DRIVE MAPPING] Done "^var.CURRENT_FILE}
M99 ; Proper exit