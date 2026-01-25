; Description: 	
;	This file should be used to create a link between two files. The file to
;	link  (param.L) will call the destination file (param.D) every time it is
;	called. An extra file will be created in /sys/links/ with the same name of
;	the link file in order to be able to check if the file was linked before to
;	this file and not overwrite it.
; 	NOTE: The param.L should be full path:
;		+ CORRECT: "/sys/homeall.g"
;		+ INCORRECT: "homeall.g"
; Input parameters:
;	- (optional) I:	Array of strings with the supported input parameters when 
;					calling the link. If it is 'null', it means the file mast
;					be called without input parameters (Ex. M98 P"/sys/bed.g").
;					If it is not present, it will support all the input
;					parameters but the result file may be too long.
; Example:
;	M98 P"/macros/files/link/create.g" L"/macros/lights/set.g"	D"/sys/modules/cbc/set.g" I{"D",}
;------------------------------------------------------------------------------
var CURRENT_FILE = "/macros/files/link/create.g"

; Checking global variables and input parameters ------------------------------
; Checking global variables
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.D)}  	Y{"Missing required input parameter D"} F{var.CURRENT_FILE} E58000
M98 P"/macros/assert/abort_if_null.g" 	R{param.D}  			Y{"Input parameter D is null"} 			F{var.CURRENT_FILE} E58001
M98 P"/macros/assert/abort_if_file_missing.g" R{param.D} 	 											F{var.CURRENT_FILE} E58002
M98 P"/macros/assert/abort_if.g" 		R{!exists(param.L)}  	Y{"Missing required input parameter L"} F{var.CURRENT_FILE} E58003
M98 P"/macros/assert/abort_if_null.g"	R{param.L}			  	Y{"Input parameter L is null"} 			F{var.CURRENT_FILE} E58004
M98 P"/macros/assert/abort_if.g" 		R{param.L == ""} 	 	Y{"Input parameter L is empty "} 		F{var.CURRENT_FILE} E58005

; Definitions -----------------------------------------------------------------
; The available parameters where implemented this way as there is bug with long
; vectors in 3.5.0
var supportedParameters = vector(21,"")
set var.supportedParameters[0]  = "A"
set var.supportedParameters[1]  = "B"
set var.supportedParameters[2]  = "C"
set var.supportedParameters[3]  = "D"
set var.supportedParameters[4]  = "E"
set var.supportedParameters[5]  = "F"
set var.supportedParameters[6]  = "H"
set var.supportedParameters[7]  = "I"
set var.supportedParameters[8]  = "J"
set var.supportedParameters[9]  = "K"
set var.supportedParameters[10] = "L"
set var.supportedParameters[11] = "O"
set var.supportedParameters[12] = "Q"
set var.supportedParameters[13] = "S"
set var.supportedParameters[14] = "T"
set var.supportedParameters[15] = "U"
set var.supportedParameters[16] = "V"
set var.supportedParameters[17] = "W"
set var.supportedParameters[18] = "X"
set var.supportedParameters[19] = "Y"
set var.supportedParameters[20] = "Z"
var SUPPORTED_PARAMETERS = var.supportedParameters ; Make it constant 

var SEPARATOR = "; ------------------------------------------------------------------------------" 

; Check if the file exists ----------------------------------------------------
var LINKS_FOLDER = "/sys/links"	; Folder where to save the links
var EXISTS_PATH = {var.LINKS_FOLDER ^ param.L} ; Final path
if(fileexists(var.EXISTS_PATH))
	M98 P{var.EXISTS_PATH} ; Calling file to get the linked file
	if (exists(global.linkedFilePath) && global.linkedFilePath == param.D)
		if(!exists(global.CONFIGURATION_UUID))
			M98 P"/macros/report/warning.g" Y{"Missing CONFIGURATION_UUID. Set /module/version first in config.g"} F{var.CURRENT_FILE} W58000
			M99 ; We consider that the version is the same.
		if(exists(global.linkedFileConfiguration) && global.linkedFileConfiguration != null && global.linkedFileConfiguration == global.CONFIGURATION_UUID)
			M99 ; WThe version is the same.

; We need to link the files ---------------------------------------------------
; Creating the file that links both files

; Linked file -----------------------------------------------------------------
; Adding the header 
echo  >{param.L}  {"; File Name:          " ^ {param.L}}
echo >>{param.L}  {"; Author:             Automatic with "^var.CURRENT_FILE}
; echo >>{param.L}  {"; Creation Date:      " ^ {state.time}}
echo >>{param.L}  {"; Description:"}
echo >>{param.L}  {";     This file is redirecting the current file to:"}
echo >>{param.L}  {";        " ^ {param.D} }
echo >>{param.L}  {";     In the current version, not all input paramters are supported."}
echo >>{param.L}  {";     NOTE: If you need a not supported parameter, you can use the"}
echo >>{param.L}  {";           file in "^var.LINKS_FOLDER^" to obtain directly call the link."}
if(exists(param.I) && (param.I != null) && (#param.I > 0))
	echo >>{param.L}  {"; Input parameters:"}
	while true
		if (iterations >= #param.I)
			break
		var LETTER = param.I[iterations] 
		echo >>{param.L} {";     "^var.LETTER^": Check the linked macro for more info."}
echo >>{param.L}  {var.SEPARATOR}

; Creating the local variables
if(!exists(param.I))
	; We will create a new variable for each input parameter and then pass 
	; this variable to the call with M98.
	echo >>{param.L}  {"; Creating variables for the supported input paramters"}
	while true
		if (iterations >= #var.SUPPORTED_PARAMETERS)
			break
		var LETTER = var.SUPPORTED_PARAMETERS[iterations] 
		echo >>{param.L}  {"var v"^var.LETTER^" = null"}
		echo >>{param.L}  {"if(exists(param."^var.LETTER^"))"}
		echo >>{param.L}  {"    set var.v"^var.LETTER^" = {param."^var.LETTER^"}"}
elif( (param.I != null) && (#param.I > 0) )
	echo >>{param.L}  {"; Creating variables for the supported input paramters"}
	while true
		if (iterations >= #param.I)
			break
		var LETTER = param.I[iterations] 
		echo >>{param.L}  {"var v"^var.LETTER^" = null"}
		echo >>{param.L}  {"if(exists(param."^var.LETTER^"))"}
		echo >>{param.L}  {"    set var.v"^var.LETTER^" = {param."^var.LETTER^"}"}
; Calling the destination file
echo >>{param.L}  {"; Calling the destination macro"}
if(!exists(param.I)) ; This link does not need input parameters.
	echo >>{param.L}  {"var vP = """^{param.D}^""""}
	echo >>>{param.L} {"M98 P{var.vP} R1"}
	; Adding the parameters
	while true
		if (iterations >= (#var.SUPPORTED_PARAMETERS-1))
			break
		var LETTER = var.SUPPORTED_PARAMETERS[iterations] 
		echo >>>{param.L} {" "^var.LETTER^"{var.v"^var.LETTER^"}"}
	; Last value with an a new line
	var LETTER = var.SUPPORTED_PARAMETERS[#var.SUPPORTED_PARAMETERS-1] 
	echo  >>{param.L} {" "^var.LETTER^"{var.v"^var.LETTER^"}"}
elif(exists(param.I) && (param.I == null) || (#param.I == 0))
	echo >>{param.L}  {"M98 P"""^{param.D}^""" R1"} ; Adding the file call with M98 without extra input parameters
else
	echo >>{param.L}  {"var vP = """^{param.D}^""""}
	echo >>>{param.L} {"M98 P{var.vP} R1"} ; Adding the file call with M98
	; Adding the supported input parameters
	var I_LENGTH = #param.I
	while true
		if (iterations >= (var.I_LENGTH - 1))
			break
		var LETTER = param.I[iterations] 
		echo >>>{param.L} {" "^var.LETTER^"{var.v"^var.LETTER^"}"}
	var LETTER = param.I[(var.I_LENGTH - 1)]
	echo >>{param.L} {" "^var.LETTER^"{var.v"^var.LETTER^"}"}

; Ready to close the file
echo >>{param.L}  {"M99 ; Proper exit this file"}

; Link available file ---------------------------------------------------------
; Now creating the file to check if the link already exists
echo  >{var.EXISTS_PATH} {"; File Name:          " ^ {var.EXISTS_PATH}}
echo >>{var.EXISTS_PATH} {"; Author:             Automatic with "^var.CURRENT_FILE}
; echo >>{var.EXISTS_PATH} {"; Creation Date:      " ^ {state.time}}
echo >>{var.EXISTS_PATH} {"; Description:"}
echo >>{var.EXISTS_PATH} {";     This file is should be used to know where a file is redirected."}
echo >>{var.EXISTS_PATH} {";     The information in this file is related to:"}
echo >>{var.EXISTS_PATH} {";         " ^ {param.L}}
echo >>{var.EXISTS_PATH} {";     Return parameters:"}
echo >>{var.EXISTS_PATH} {";         - global.linkedFilePath: Destination path"}
echo >>{var.EXISTS_PATH} {var.SEPARATOR}
echo >>{var.EXISTS_PATH} {"if !exists(global.linkedFilePath)"}
echo >>{var.EXISTS_PATH} {"    global linkedFilePath = """^{param.D}^""""}
echo >>{var.EXISTS_PATH} {"else"}
echo >>{var.EXISTS_PATH} {"    set global.linkedFilePath = """^{param.D}^""""}
if(exists(global.CONFIGURATION_UUID))
	echo >>{var.EXISTS_PATH} {"if !exists(global.linkedFileConfiguration)"}
	echo >>{var.EXISTS_PATH} {"    global linkedFileConfiguration = """^{global.CONFIGURATION_UUID}^""""}
	echo >>{var.EXISTS_PATH} {"else"}
	echo >>{var.EXISTS_PATH} {"    set global.linkedFileConfiguration = """^{global.CONFIGURATION_UUID}^""""}
else
	echo >>{var.EXISTS_PATH} {"if !exists(global.linkedFileConfiguration)"}
	echo >>{var.EXISTS_PATH} {"    global linkedFileConfiguration = null"}
	echo >>{var.EXISTS_PATH} {"else"}
	echo >>{var.EXISTS_PATH} {"    set global.linkedFileConfiguration = null"}
echo >>{var.EXISTS_PATH} {"M99 ; Proper exit"}

; Link properly created -------------------------------------------------------
M118 S{"Link created between "^param.L^" and "^param.D}

; -----------------------------------------------------------------------------
M99 ; Exit current macro