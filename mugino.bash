#!/bin/bash
#
# Mugino CUDA Super Scaler for *nix
#

#########################################################################################################
## USER: Edit these for your system 
## Default Locations
VAL_DIR_INJECT_IN="/home/mugino/Inject"
VAL_DIR_MASTER_IN="/home/mugino/Input"
VAL_DIR_MASTER_OUT="/home/mugino/Output"
## System location
VAL_DIR_CSS="/opt/mugino-css"
## EMPH Workspace
VAL_DIR_TEMP="/mnt/photostor0"
## Where will files be copyed (for input projection mode only)
VAL_DIR_CPIN="/mnt/photostor0"
## What image size should triger EMPH? If you have more RAM you can make this higher
## This is the longest edge, in pixels. This must be a number, no text
SET_VAL_EMPH_TRIG="3000"
## System Mode
## Should the system display a gui when its running?


SET_MODE_INJ=0
SET_MODE_NR=0
SET_MODE_SCALE=2
SET_MODE_KIFR=0
SET_VAL_MAXINRES=0
SET_MODE_MAXINSE=0
SET_MODE_CPIN=0
SET_MODE_NOCHECK=0
debugmode=0
# Define Main Back Title and GPU Name
mastertitle="Mugino CSS v2.71_29-10-2015"


USAGE()
{
	echo "$mastertitle"
	echo "------------------------------------------------"
	echo "USAGE: -x <S> -m <S> [-n] [-i <S>] [-o <S>] [-k or -K] [-O <#>[_s] [-c] [-y]"
	echo ""
	echo "	-x Exec Mode (String)"
	echo "		run - Runs a new job"
	echo "		prep - Generates the job file only (For running later or transport)"
	echo "		p-run - Runs the prepared job file, must be in CSS directory"
	echo "		inject - Inject a project(s) into the current job (will run after current ITEM)"
	echo "		append - Append a project(s) after the current job (will run after current JOB)"
	echo "		recover - Recover orginal image from output image, MUST HAVE USED KIFR!"
	echo ""
	echo "	-m Scaler Mode (String)"
	echo "		2 - 2x Scale Mode"
	echo "		4 - 4x Scale Mode"
	echo "		0 - No scaling, for NR only mode"
	echo ""
	echo "	-n Noise Reduction"
	echo ""
	echo "	-i/-o Input/Output"
	echo "		Overrides the default dirs"
	echo "		DO NOT PUT A '/' ON THE END "
	echo ""
	echo "	-c Move input items"
	echo "		When dealing with a non-static input, this will copy the input for safty"
	echo ""
	echo "	-k KIFR (Keep Input for Recovery)"
	echo "		This uses steganography to place the original file in the output for recovery"
	echo "		Uses the Input image file as a payload"
	echo "		This was added for as a P.O.C. for a class at university"
	echo ""
	echo "		WARNING!!"
	echo "		 1. DO NOT re-save the image with any editor, the embedded image WILL be LOST"
	echo "		 2. This WILL increase the output file size"
	echo "		 3. This will take some CPU power to pull off and will extend the time"
	echo "		 4. This does not play well with transparent images, transparently will become black"
	echo "		    in areas that it has written to. So some images will be half transparent half black bg"
	echo "		 5. The embedding can fail when doing NR only as the file size may not be big enough"
	echo ""
	echo "	-O Omit (Number), Omit any file that is larger then X"
	echo "		Add_s to use short edge, default is long edge"
	echo ""
	echo "	-y Will skip confirm and run"
}

if [ $# -lt 2 ]; then echo "[PEBKAC] You need to define options, use -h"; USAGE; exit 1; fi;

echo ""; echo "$mastertitle"; echo "------------------------------------------------"

while getopts ":x:m:ni:o:kO:hcyV" opt; do
  case $opt in
    x) SET_MODE_EXEC=$OPTARG;;
	m) SET_MODE_SCALE=$OPTARG;;
	n) SET_MODE_NR=1;;
	i) if [ $SET_MODE_EXEC = "inject" ]; then VAL_DIR_INJECT_IN="$OPTARG"; else VAL_DIR_MASTER_IN="$OPTARG"; fi;;
	o) VAL_DIR_MASTER_OUT="$OPTARG" >&2;;
	k) SET_MODE_KIFR=1;;
	O) SET_VAL_MAXINRES=$(awk -F _ '{print $1}' < <(echo "$OPTARG")); if [ $(awk -F _ '{print $2}' < <(echo "$OPTARG") || echo l) = "s" ]; then SET_MODE_MAXINSE=1; fi;;
	c) SET_MODE_CPIN=1; echo "[E500] Not Implimented, will be ignored, Abort";;
	y) SET_MODE_NOCHECK=1;;
	h) USAGE; exit 1;;
	V) debugmode=1;;
    \?) echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"; USAGE; exit 1;;
    :) echo "[PEBKAC] -$OPTARG requires an argument, Abort"; USAGE; exit 1;;
  esac
done



if [ $SET_MODE_NOCHECK = 0 ]; then
	if [ $SET_MODE_EXEC = "run" ]; then
		echo "Exec Mode: Full Run"
		if [ $SET_MODE_SCALE = 0 ]; then echo "Scale Mode: OFF"; else echo "Scale Mode: ${SET_MODE_SCALE}x"; fi
		if [ $SET_MODE_NR = 1 ]; then echo "Noise Reduction: ON"; else echo "Noise Reduction: OFF"; fi
		echo "Input: ${VAL_DIR_MASTER_IN}"
		echo "Output: ${VAL_DIR_MASTER_OUT}"
		if [ $SET_VAL_MAXINRES = 0 ]; then echo "Max Input: OFF"; else echo "Max Input: <= ${SET_VAL_MAXINRES}px $(if [ $SET_MODE_MAXINSE = 1 ]; then echo "(Short Edge)"; fi)"; fi
		if [ $SET_MODE_KIFR = 0 ]; then echo "Input Recovery: OFF"; else echo "Input Recovery: ON"; fi
		if [ $SET_MODE_CPIN = 0 ]; then echo "Copy Input: OFF"; else echo "Copy Input: ON"; fi
	elif [ $SET_MODE_EXEC = "prep" ]; then
		echo "Exec Mode: Prep Only"
		if [ $SET_MODE_SCALE = 0 ]; then echo "Scale Mode: OFF"; else echo "Scale Mode: ${SET_MODE_SCALE}x"; fi
		if [ $SET_MODE_NR = 1 ]; then echo "Noise Reduction: ON"; else echo "Noise Reduction: OFF"; fi
		echo "Input: ${VAL_DIR_MASTER_IN}"
		echo "Output: ${VAL_DIR_MASTER_OUT}"
		if [ $SET_VAL_MAXINRES = 0 ]; then echo "Max Input: OFF"; else echo "Max Input: <= ${SET_VAL_MAXINRES}px $(if [ $SET_MODE_MAXINSE = 1 ]; then echo "(Short Edge)"; fi)"; fi
		if [ $SET_MODE_KIFR = 0 ]; then echo "Input Recovery: OFF"; else echo "Input Recovery: ON"; fi
		if [ $SET_MODE_CPIN = 0 ]; then echo "Copy Input: OFF"; else echo "Copy Input: ON"; fi
	elif [ $SET_MODE_EXEC = "p-run" ]; then
		echo "Exec Mode: Run from preped data"
		echo "Will follow job file, all options are ignored!"
	elif [ $SET_MODE_EXEC = "inject" ]; then
		echo "Exec Mode: Injection"
		if [ $SET_MODE_SCALE = 0 ]; then echo "Scale Mode: OFF"; else echo "Scale Mode: ${SET_MODE_SCALE}x"; fi
		if [ $SET_MODE_NR = 1 ]; then echo "Noise Reduction: ON"; else echo "Noise Reduction: OFF"; fi
		echo "Input: ${VAL_DIR_INJECT_IN}"
		echo "Output: ${VAL_DIR_MASTER_OUT}"
		if [ $SET_VAL_MAXINRES = 0 ]; then echo "Max Input: OFF"; else echo "Max Input: <= ${SET_VAL_MAXINRES}px $(if [ $SET_MODE_MAXINSE = 1 ]; then echo "(Short Edge)"; fi)"; fi
		if [ $SET_MODE_KIFR = 0 ]; then echo "Input Recovery: OFF"; else echo "Input Recovery: ON"; fi
		if [ $SET_MODE_CPIN = 0 ]; then echo "Copy Input: OFF"; else echo "Copy Input: ON"; fi
	elif [ $SET_MODE_EXEC = "append" ]; then
		echo "Exec Mode: Append"
		if [ $SET_MODE_SCALE = 0 ]; then echo "Scale Mode: OFF"; else echo "Scale Mode: ${SET_MODE_SCALE}x"; fi
		if [ $SET_MODE_NR = 1 ]; then echo "Noise Reduction: ON"; else echo "Noise Reduction: OFF"; fi
		echo "Input: ${VAL_DIR_INJECT_IN}"
		echo "Output: ${VAL_DIR_MASTER_OUT}"
		if [ $SET_VAL_MAXINRES = 0 ]; then echo "Max Input: OFF"; else echo "Max Input: <= ${SET_VAL_MAXINRES}px $(if [ $SET_MODE_MAXINSE = 1 ]; then echo "(Short Edge)"; fi)"; fi
		if [ $SET_MODE_KIFR = 0 ]; then echo "Input Recovery: OFF"; else echo "Input Recovery: ON"; fi
		if [ $SET_MODE_CPIN = 0 ]; then echo "Copy Input: OFF"; else echo "Copy Input: ON"; fi
	elif [ $SET_MODE_EXEC = "recover" ]; then
		echo "Exec Mode: Input Recovery"
		echo "Input: ${VAL_DIR_MASTER_IN}"
		echo "Output: ${VAL_DIR_MASTER_OUT}"
	else
		echo "[PEBKAC] No Exec Mode was defined or was not correct, Abort"
		exit 1
	fi
	echo "------------------------------------------------"
	read -p "Are you ready to run this job? (y/n) " cmdrep
	case $cmdrep in
		[n]* ) exit 1;;
		[y]* ) echo "Tail log for status";;
		* ) exit 1;;
	esac
elif [ $SET_MODE_NOCHECK = 1 ]; then echo "Tail log for status"; fi

if [ $debugmode = 0 ]; then 
nohup bash ${VAL_DIR_CSS}/mugino-worker.bash  "MCSS-IPPvCommit-9c4ce55d-be5e-4411-987a-d1db09127f9a:${SET_MODE_EXEC}:${SET_MODE_INJ}:${SET_MODE_SCALE}:${SET_MODE_NR}:${SET_VAL_MAXINRES}:${SET_MODE_KIFR}:${SET_MODE_CPIN}:${SET_VAL_EMPH_TRIG}:${VAL_DIR_MASTER_IN}:${VAL_DIR_MASTER_OUT}:${VAL_DIR_INJECT_IN}:${VAL_DIR_CSS}:${VAL_DIR_TEMP}:${VAL_DIR_CPIN}:${SET_MODE_MAXINSE}" &
fi
if [ $debugmode = 1 ]; then
echo "DEBUG MODE ON"
echo "Sending these vars to the worker:"
echo "NOENTRYCODE: MCSS-IPPvCommit-9c4ce55d-be5e-4411-987a-d1db09127f9a"
echo "EXEC MODE: ${SET_MODE_EXEC}"
echo "INJECT SWITCH: ${SET_MODE_INJ}"
echo "SCALE MODE: ${SET_MODE_SCALE}"
echo "NOISE REDUCTION SWITCH: ${SET_MODE_NR}"
echo "MAX INPUT RES VAL: ${SET_VAL_MAXINRES}"
echo "KIFR SWITCH: ${SET_MODE_KIFR}"
echo "CPIN SWITCH: ${SET_MODE_CPIN}"
echo "EMPH TRIGGER VAL: ${SET_VAL_EMPH_TRIG}"
echo "MASTER IN VAL: ${VAL_DIR_MASTER_IN}"
echo "MASTER OUT VAL: ${VAL_DIR_MASTER_OUT}"
echo "MASTER INJECT IN VAL: ${VAL_DIR_INJECT_IN}"
echo "SYSTEM DIR VAL: ${VAL_DIR_CSS}"
echo "TEMP DIR VAL: ${VAL_DIR_TEMP}"
echo "CPIN DIR VAL: ${VAL_DIR_CPIN}"
echo "SHORTEND SWITCH: ${SET_MODE_MAXINSE}"
sleep 2
bash -x ${VAL_DIR_CSS}/mugino-worker.bash  "MCSS-IPPvCommit-9c4ce55d-be5e-4411-987a-d1db09127f9a:${SET_MODE_EXEC}:${SET_MODE_INJ}:${SET_MODE_SCALE}:${SET_MODE_NR}:${SET_VAL_MAXINRES}:${SET_MODE_KIFR}:${SET_MODE_CPIN}:${SET_VAL_EMPH_TRIG}:${VAL_DIR_MASTER_IN}:${VAL_DIR_MASTER_OUT}:${VAL_DIR_INJECT_IN}:${VAL_DIR_CSS}:${VAL_DIR_TEMP}:${VAL_DIR_CPIN}:${SET_MODE_MAXINSE}"
fi
