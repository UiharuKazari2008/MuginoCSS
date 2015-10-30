#!/bin/bash
#
# Mugino CUDA Super Scaler for *nix
#
#########################################################################################################
## USER: Edit these for your system 
## Default Locations
dir_master_inject="/home/mugino/Inject"
dir_master_in="/home/mugino/Input"
dir_master_out="/home/mugino/Output"

## System location
dir_ccs="/opt/mugino-css"
dir_tmp="/mnt/photostor0"
## What image size should triger EMPH? If you have more RAM you can make this higher
## This is the longest edge, in pixels. This must be a number, no text
var_emph_trigger="3000"
## System Mode
## Should the system display a gui when its running?

################################### Runtime ###################################

Get_Data_File2Pross()
{
	#Get HxW
	hf=$(identify -format "%h" "${1}${3}" 2>> ${dir_ccs}/mcss.log)
	wf=$(identify -format "%w" "${1}${3}" 2>> ${dir_ccs}/mcss.log)
	mf=$(identify -format "%m" "${1}${3}" 2>> ${dir_ccs}/mcss.log)
	#Find longest edge
	if [ $hf -ge $wf ] 2>> ${dir_ccs}/mcss.log; then
		fres=$hf
	else
		fres=$wf
	fi
	#Check if Inkect
	if [ ${injectmode} = 1 ]; then
		# If file falls within rangle run EMPH
		if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
			#Mark for EMPH
			echo "[TKG2] 		INJECT-EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):1" 1>> ${dir_ccs}/inject.projob
		else
			# Mark for normal
			echo "[TKG2] 		INJECT-STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):1" 1>> ${dir_ccs}/inject.projob
		fi
	# If its not a Inject do this
	else
		# Does it not use Max Input Size filtering
		if [ $max_input = 0 ]; then
			# If file falls within rangle run EMPH
			if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
				#Mark for EMPH
				echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${dir_ccs}/taskmgr.projob
			else
				# Mark for normal
				echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${dir_ccs}/taskmgr.projob
			fi
		# Max Input Size filtering
		else
			if [ $fres -le $max_input  ]; then
				# If file falls within rangle run EMPH
				if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
					#Mark for EMPH
					echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
					echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${dir_ccs}/taskmgr.projob
				else
					# Mark for normal
					echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
					echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${dir_ccs}/taskmgr.projob
				fi
			fi
		fi
	fi
	##### Input:Output:File:Mode:NR:Project:ProjectNum:Preproccess > projob file
}

Runtime_TasKGen_InjectGen()
{
	echo "[TKG2] >> Injecting items into current project..." >> ${dir_ccs}/mcss.log
	curdir="$(pwd)"
	cd ${dir_ccs}
	# Inject data at line 2
	sed -i '1r inject.projob' taskmgr.projob
	cd "$curdir"
	echo "[TKG2] >> Injection Complete, Wait till current item is complete." >> ${dir_ccs}/mcss.log
}

Runtime_TasKGen_AppendGen()
{
	echo "[TKG2] >> Appending items into current project..." >> ${dir_ccs}/mcss.log
	# Inject data at end of file
	cat "${dir_ccs}/inject.projob" >> ${dir_ccs}/taskmgr.projob
	echo "[TKG2] >> Append Complete, Wait till current item is complete." >> ${dir_ccs}/mcss.log
}

# Mode, NR?, Input, Output, Save projob where? (2 1 "/input" "/output" noproj)
Runtime_Core_TasKGen()
{
	cd "${3}"
	echo "[CORE] ------------------------------ Switching Mode ------------------------------" >> ${dir_ccs}/mcss.log
	echo "[----] TasKGen 2 (v1.2) - The New Mugino Job Manager!" >> ${dir_ccs}/mcss.log
	if [ ${injectmode} = 1 ]; then
		echo "[TKG2] >> This is a inject! the current job is on hold!" >> ${dir_ccs}/mcss.log
	fi
	echo "[TKG2] >> Doing some math.." >> ${dir_ccs}/mcss.log
	project_totalnum=0
	project_totalnum=$(ls -d */ 2> /dev/null | wc -l)
	single_totalnum=$(ls *.* 2> /dev/null | wc -l)
	echo "[TKG2] >> Projects Found: ${project_totalnum} / Single Items Found: ${single_totalnum}" >> ${dir_ccs}/mcss.log
	echo "[TKG2] >> Geneating projects and jobs..." >> ${dir_ccs}/mcss.log
	if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
		for dirl1 in */ ; do
			echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
			echo "[TKG2] >> Project: ${dirl1}" >> ${dir_ccs}/mcss.log
			echo "[TKG2] >> Contex is now /${dirl1}" >> ${dir_ccs}/mcss.log
			cd "${dirl1}"
			if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
				for dirl2 in */ ; do
					{
						cd "${dirl2}"
						if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
							for dirl3 in */ ; do
								{
									cd "${dirl3}"
									if [ $(ls *.* 2> /dev/null | wc -l) != 0 ]; then
										echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
										echo "[TKG2] >> Contex is now /../../${dirl3}" >> ${dir_ccs}/mcss.log
										for filedl3 in *.# ; do
											Get_Data_File2Pross "${3}/${dirl1}${dirl2}${dirl3}" "${4}/${dirl1}${dirl2}${dirl3}" "${filedl3}" $1 $2 "${dirl1}" $6
										done
										[ -d "${4}/${dirl1}${dirl2}${dirl3}" ] || mkdir -p "${4}/${dirl1}${dirl2}${dirl3}"
										fi
									cd .. 2> /dev/null
								}
							done
						fi
							{
								if [ $(ls *.*  2> /dev/null | wc -l) != 0 ]; then
									echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
									echo "[TKG2] >> Contex is now /../${dirl2}" >> ${dir_ccs}/mcss.log
									for filedl2 in *.* ; do
										Get_Data_File2Pross "${3}/${dirl1}${dirl2}" "${4}/${dirl1}${dirl2}" "${filedl2}" $1 $2 "${dirl1}" $6
									done
									[ -d "${4}/${dirl1}${dirl2}" ] || mkdir -p "${4}/${dirl1}${dirl2}"
								fi
								cd .. 2> /dev/null
							}
					}
				done
			fi
			{
				if [ $(ls *.* 2> /dev/null | wc -l) != 0 ]; then
					echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
					echo "[TKG2] >> Contex is now /${dirl1}" >> ${dir_ccs}/mcss.log
					for filedl1 in *.* ; do
						Get_Data_File2Pross "${3}/${dirl1}" "${4}/${dirl1}" "${filedl1}" $1 $2 "${dirl1}" $6
					done
					[ -d "${4}/${dirl1}" ] || mkdir -p "${4}/${dirl1}"
				fi
				cd .. 2> /dev/null
			}
		done
	fi
	if [ $(ls *.* 2> /dev/null | wc -l) != 0 ]; then
		echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
		echo "[TKG2] >> Contex is now /" >> ${dir_ccs}/mcss.log
		for filedl0 in *.* ; do
			Get_Data_File2Pross "${3}/" "${4}/" "${filedl0}" $1 $2 "N/A" $6
		done
		[ -d "${4}" ] || mkdir -p "${4}"
	fi
}


################################### MCSS ###################################
## MCSS Runtime (Scale Mode)
# Input(s): File (Piped String (MCSS ? Image, Out of contex), Mode (Piped String)
# Outputs (s): File (Piped String (MCSS PNG Image, No contex)
Runtime_Core_WaifuCSS() 
{
	echo "[CORE] ------------------------------ Switching Mode ------------------------------" >> ${dir_ccs}/mcss.log
	echo "[----] Mugino Meltdowner Runtime (v1.6)" >> ${dir_ccs}/mcss.log
	run=1
	# Item Loop
	{
		while [ $(wc -l < ${dir_ccs}/taskmgr.projob) != 0 ]; do
			#Get Line for item to do
			item="$(head -1 ${dir_ccs}/taskmgr.projob)"
			#Get I/O and Filename(and with no ext)
			item_in="$(awk -F : '{print $1}' < <(echo $item))"
			item_out="$(awk -F : '{print $2}' < <(echo $item))"
			item_filename="$(awk -F : '{print $3}' < <(echo $item))"
			item_filename_out="$(echo ${item_filename} | cut -d '.' -f1)"
			item_embed="$(awk -F : '{print $7}' < <(echo $item))"
			# Get Mode
			item_mode=$(awk -F : '{print $4}' < <(echo $item))
			# Get Settings and determin commnd line options
			item_settings=$(awk -F : '{print $5}' < <(echo $item))
			if [ $item_settings = 1 ]; then
				if [ $item_mode = 0 ]; then
					prossmode="noise -noise_level 1"
					settingstext="NR"
				else
					prossmode="noise_scale -noise_level 1"
					settingstext="${item_mode}x+NR"				
				fi

			fi
			if [ $item_settings = 0 ]; then
				prossmode="scale"
				settingstext="${item_mode}x"
			fi
			# Does it require EMPH
			item_prepross=$(awk -F : '{print $8}' < <(echo $item) | awk -F - '{print $1}')
			# STD item, do not run EMPH
			if [ $item_prepross = "STD" ]; then
				item_prepross=0
			else
				#EMPH needed, get the grid size
				item_prepross=1
				item_emphgrid=$(awk -F : '{print $8}' < <(echo $item) | awk -F - '{print $2}')
			fi
			# Get items dimentions, file type, and its file size
			item_dimen="$(awk -F : '{print $9}' < <(echo $item)) x $(awk -F : '{print $10}' < <(echo $item))"
			item_type=$(awk -F : '{print $12}' < <(echo $item))
			item_size=$(awk -F : '{print $13}' < <(echo $item))
			injectmode=$(awk -F : '{print $14}' < <(echo $item))
			# Run EPH then STD
			if [ $item_prepross = 1 ]; then
				cd "${dir_emph_blocks}/in"
				echo "[MMRT] >>>> EMPH ${item_filename_out} ${item_dimen} ${item_size} [${settingstext}]" >> ${dir_ccs}/mcss.log
				# Cut file by given grid
				echo "[EMPH] >>>> Prepareing ${item_emphgrid} grid..." >> ${dir_ccs}/mcss.log
				convert "${item_in}${item_filename}" -crop ${item_emphgrid}@ +repage +adjoin "emo_block_%d" &>> ${dir_ccs}/mcss.log
				totalblocks="$(ls emo_block_* | wc -l)"
				currentblock=1
				#break
				echo "[Meltdowner] >>>> Running Meltdowner on blocks..." >> ${dir_ccs}/mcss.log
				for block in emo_block_*; do
					cd  /opt/mugino-css/waifu2x/
					if [ $item_mode = 4 ]; then
						th waifu2x.lua -m ${prossmode} -i "${dir_emph_blocks}/in/${block}"  -o "${dir_ccs}/4xdata.png"  &>> ${dir_ccs}/mcss.log
						echo "[WARN!] >>>> 4x Mode is not completely ready, EMPH is not setup to check the output" >> ${dir_ccs}/mcss.log
						th waifu2x.lua -m ${prossmode} -i "${dir_ccs}/4xdata.png"  -o "${dir_emph_blocks}/out/${block}.png"  &>> ${dir_ccs}/mcss.log
						rm "${dir_ccs}/4xdata.png"
					else
						th waifu2x.lua -m ${prossmode} -i "${dir_emph_blocks}/in/${block}"  -o "${dir_emph_blocks}/out/${block}.png"  &>> ${dir_ccs}/mcss.log
					fi
					currentblock=$(( currentblock + 1 ))
				done
				cd "${dir_emph_blocks}/out"
				# If there is more then 9, rename them
				if [ ${item_emphgrid} != "3x3" ]; then
					mv emo_block_0.png emo_block_00.png
					mv emo_block_1.png emo_block_01.png
					mv emo_block_2.png emo_block_02.png
					mv emo_block_3.png emo_block_03.png
					mv emo_block_4.png emo_block_04.png
					mv emo_block_5.png emo_block_05.png
					mv emo_block_6.png emo_block_06.png
					mv emo_block_7.png emo_block_07.png
					mv emo_block_8.png emo_block_08.png
					mv emo_block_9.png emo_block_09.png
				fi
				# Runtime
				echo "[EMPH] >>>> Compleing output..." >> ${dir_ccs}/mcss.log
				montage -mode concatenate -tile ${item_emphgrid} emo_block_* "${item_out}${item_filename_out}(MCSS-${settingstext}).png" &>> ${dir_ccs}/mcss.log
				# Remove old blocks from EMo
				rm emo_block_*
				cd "${dir_emph_blocks}/in"
				rm emo_block_*
			fi
			# Run STD
			if [ $item_prepross = 0 ]; then
				# Run Scaler with input from the current mode
				echo "[Meltdowner] >>>> STD ${item_filename_out} ${item_dimen} ${item_size} [${settingstext}]" >> ${dir_ccs}/mcss.log
				cd  /opt/mugino-css/waifu2x/
				if [ $item_mode = 4 ]; then
					th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${dir_ccs}/4xdata.png"  &>> ${dir_ccs}/mcss.log
					th waifu2x.lua -m ${prossmode} -i "${dir_ccs}/4xdata.png"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${dir_ccs}/mcss.log
					rm "${dir_ccs}/4xdata.png"
				else
					th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${dir_ccs}/mcss.log
				fi
			fi
			# Embed if required
			if [ $item_embed = 1 ]; then
				echo "[KIFR] >>> Embedding Input File..." >> ${dir_ccs}/mcss.log
				stepic --encode --image-in="${item_out}${item_filename_out}(MCSS-${settingstext}).png" --data-in="${item_in}${item_filename}" --out="${item_out}${item_filename_out}(MCSS-${settingstext}+E).png" &>> ${dir_ccs}/mcss.log
				rm "${item_out}${item_filename_out}(MCSS-${settingstext}).png"
			fi
			echo $item &>> ${dir_ccs}/taskmgr_bk.projob
			sed -i '1d' ${dir_ccs}/taskmgr.projob
		done
	}
	echo "[TKG2] >> Job is complete" >> ${dir_ccs}/mcss.log
}

Header()
{
	echo "" >> ${dir_ccs}/mcss.log
	echo "" >> ${dir_ccs}/mcss.log
	echo "----- $(date) -------------------------------------------------------------" >> ${dir_ccs}/mcss.log
	echo "${mastertitle}" >> ${dir_ccs}/mcss.log
	echo "[CORE] > Proccesser Card = ${gpuname}" >> ${dir_ccs}/mcss.log
	echo "[CORE] > Proccesser Card Cores = ${gpucores}" >> ${dir_ccs}/mcss.log
	dir_emph_blocks="${dir_tmp}/mcss/blks"
	oprtan0=""
	[ -d "${dir_emph_blocks}/in" ] || mkdir -p "${dir_emph_blocks}/in/"
	[ -d "${dir_emph_blocks}/out" ] || mkdir -p "${dir_emph_blocks}/out/"
}

usage()
{
	echo "$mastertitle"
	echo "------------------------------------------------"
	echo "Usage: -x <S> -m <S> [-n] [-i <S>] [-o <S>] [-k or -K] [-O <#>] [-c]"
	echo ""
	echo "	-x Exec Mode (String)"
	echo "		run - Runs a new job"
	echo "		prep - Generates the job file only (For running later or transport)"
	echo "		p-run - Runs the prepared job file, must be in CSS directory"
	echo "		inject - Inject a project(s) into the current job (will run after current item)"
	echo "		append - Append a project(s) after the current job (will run after current job)"
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
	echo ""
	echo "	-O Omit (Number), Omit any file that is larger then X"
	echo ""
	echo "	-c Move input items"
	echo "		When dealing with a non-static input, this will copy the input for safty"
}

## EMPH Grid calculator
Get_Data_CropLvl() {
#Get grid size
if [ $1 -le 3000 ]
then
echo "3x3"
break
fi
if [ $1 -le 7000 ]
then
echo "4x4"
break
else
if [ $1 -le 9000 ]
then
echo "5x5"
break
else
if [ $1 -le 14000 ]
then
echo "6x6"
break
else
if [ $1 -le 17000 ]
then
echo "7x7"
break
else
if [ $1 -le 20000 ]
then
echo "8x8"
break
else
if [ $1 -le 23000 ]
then
echo "9x9"
break
else
if [ $1 -le 27000 ]
then
echo "10x10"
break
else
if [ $1 -le 30000 ]
then
echo "11x11"
break
else
if [ $1 -le 32000 ]
then
echo "12x12"
break
fi
fi
fi
fi
fi
fi
fi
fi
fi
}

# Misc Var Init
totalitems=0
project_totalnum=0
project_tempassnum=0
project_totalnum=0
single_totalnum=0
injectmode=0
oprtan0=0
noise_reduction=0
scale=2
stegno=0
max_input=0
copy_input=0
# Define Main Back Title and GPU Name
mastertitle="Mugino CUDA Super Scaler v2.67_29-10-2015"
gpuname="$(nvidia-smi -q | grep "Product Name " | cut -c 39-)"
gpucores="$(/cuda/NVIDIA_CUDA-7.5_Samples/1_Utilities/deviceQuery/deviceQuery | grep "CUDA Cores")"

if [ $# -lt 2 ]; then
	echo "[PEBKAC] You need to define options, use -h"
	usage
	exit 1
fi

echo ""
echo "$mastertitle"
echo "------------------------------------------------"

while getopts ":x:mn:i:o:kO:hc" opt; do
  case $opt in
    x)
	  # Set Execution Mode
	  run_mode=$OPTARG
      ;;
	m)
      scale=$OPTARG
      ;;
	n)
	  # Enable Noise Reduction Mode
	  noise_reduction=1
	  ;;
	i)
	  if [ $run_mode = "inject" ]; then
		dir_master_inject="$OPTARG"
	  else
		dir_master_in="$OPTARG"
	  fi
      ;;
	o)
      dir_master_out="$OPTARG" >&2
      ;;
	k)
      stegno=1
      ;;
	K)
      stegno=2
      ;;
	O)
      max_input=$OPTARG
      ;;
	c)
      copy_input=1
	  echo "[E500] Not Implimented, will be ignored, Abort"
      ;;
	h)
      usage
	  exit 1
      ;;
    \?)
      echo "[PEBKAC] WTF is -$OPTARG?, thats not a accepted option, Abort"
	  usage
      exit 1
      ;;
    :)
      echo "[PEBKAC] -$OPTARG requires an argument, Abort"
	  usage
      exit 1
      ;;
  esac
done
if [ $run_mode = "run" ]; then
	echo "Exec Mode: Full Run"
elif [ $run_mode = "prep" ]; then
	echo "Exec Mode: Prep Only"
elif [ $run_mode = "p-run" ]; then
	echo "Exec Mode: Run from preped data"
elif [ $run_mode = "inject" ]; then
	echo "Exec Mode: Injection"
elif [ $run_mode = "append" ]; then
	echo "Exec Mode: Append"
elif [ $run_mode = "recover" ]; then
	echo "Exec Mode: Recovery"
else
	echo "[PEBKAC] No Exec Mode was defined or was not correct, Abort"
	exit 1
fi

if [ $scale = 0 ]; then
	echo "Scale Mode: OFF"
else
	echo "Scale Mode: ${scale}x"
fi
if [ $noise_reduction = 1 ]; then
	echo "Noise Reduction: ON"
else
	echo "Noise Reduction: OFF"
fi
if [ $run_mode = "inject" ]; then
	echo "Input: ${dir_master_inject}"
else
	echo "Input: ${dir_master_in}"
fi
echo "Output: ${dir_master_out}"
if [ $max_input = 0 ]; then
	echo "Max Input: DISABLED"
else
	echo "Max Input: ${max_input}px"
fi
if [ $stegno = 0 ]; then
	echo "Input Recovery: OFF"
else
	echo "Input Recovery: ON"
fi
if [ $copy_input = 0 ]; then
	echo "Copy Input: OFF"
else
	echo "Copy Input: ON"
fi
echo "------------------------------------------------"
read -p "Are you ready to run this job? (y/n) " cmdrep
case $cmdrep in
	[no]* ) exit 1;;
	[yes]* ) echo "Tail log for status";;
	* )     echo "No rep";;
esac

if [ $run_mode = "run" ]; then
	#Full Run Mode with Prep Stage
	Header
	rm ${dir_ccs}/taskmgr.projob 2> /dev/null
	Runtime_Core_TasKGen $scale $noise_reduction "${dir_master_in}" "${dir_master_out}" $copy_input $stegno
	Runtime_Core_WaifuCSS
	rm ${dir_ccs}/taskmgr.projob 2> /dev/null
elif [ $run_mode = "prep" ]; then
	Header
	#Prepare Job file, useful if not running at that moment
	rm ${dir_ccs}/taskmgr.projob 2> /dev/null
	echo "[CORE] > Running as: Prep-only Mode" >> ${dir_ccs}/mcss.log
	Runtime_Core_TasKGen $scale $noise_reduction "${dir_master_in}" "${dir_master_out}" $copy_input $stegno
elif [ $run_mode = "p-run" ]; then
	Header
	echo "[CORE] > Running as: Run-only Mode" >> ${dir_ccs}/mcss.log
	Runtime_Core_WaifuCSS
	rm ${dir_ccs}/taskmgr.projob 2> /dev/null
elif [ $run_mode = "inject" ]; then
	# Inject items into the current job
	injectmode=1
	rm ${dir_ccs}/inject.projob 2> /dev/null
	Runtime_Core_TasKGen $scale $noise_reduction "${dir_master_inject}" "${dir_master_out}" $copy_input $stegno
	Runtime_TasKGen_InjectGen
	rm ${dir_ccs}/inject.projob 2> /dev/null
elif [ $run_mode = "append" ]; then
	# Inject items into the current job
	injectmode=1
	rm ${dir_ccs}/inject.projob 2> /dev/null
	Runtime_Core_TasKGen $scale $noise_reduction "${dir_master_inject}" "${dir_master_out}" $copy_input $stegno
	Runtime_TasKGen_AppendGen
	rm ${dir_ccs}/inject.projob 2> /dev/null
elif [ $run_mode = "recover" ]; then
	Header
	echo "[CORE] > Running as: Image Recovery Mode" >> ${dir_ccs}/mcss.log
	[ -d "${dir_master_out}/Recovery/" ] || mkdir -p "${dir_master_out}/Recovery/"
	cd "${dir_master_in}"
	for inputfile in *.png; do
		stepic --decode --image-in="${inputfile}" -out="${dir_master_out}/Recovery/RECOVERED-${inputfile}" &>> ${dir_ccs}/mcss.log
	done
else
	echo "[PEBKAC] No Exec Mode was defined or was not correct, Abort"
	exit 1
fi
