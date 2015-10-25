#!/bin/bash
#
# Mugino CUDA Super Scaler for *nix
#
#########################################################################################################
## USER: Edit these for your system 
# Define Locations
## Main Input and Output for Single File Job
dir_master_inject="/home/mugino/Inject"
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
	if [ ${injectmode} = "inj" ]; then
		# If file falls within rangle run EMPH
		if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
		#Mark for EMPH
		echo "[TKG2] 		INJECT-EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
		echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/inject.taskmgr.projob
		else
		echo "[TKG2] 		INJECT-STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
		echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/inject.taskmgr.projob
		fi
	else
		if [ $maxinpuuseage = 0 ]; then
			# If file falls within rangle run EMPH
			if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
			#Mark for EMPH
			echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/taskmgr.projob
			else
			echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/taskmgr.projob
			fi
		fi
		if [ $maxinpuuseage = 1 ]; then
			if [ $fres -le $maxinputrse  ]; then
				# If file falls within rangle run EMPH
				if [ $fres -ge $var_emph_trigger ] 2>> ${dir_ccs}/mcss.log; then
				#Mark for EMPH
				echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(Get_Data_CropLvl $fres):${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/taskmgr.projob
				else
				echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${dir_ccs}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${fres}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//')" 1>> ${dir_ccs}/taskmgr.projob
				fi
			fi
		fi
	fi
	##### Input:Output:File:Mode:NR:Project:ProjectNum:Preproccess > projob file
}

# Mode, NR?, Input, Output, Save projob where? (2 1 "/input" "/output" noproj)
Runtime_Core_TasKGen()
{
cd "${3}"
echo "[CORE] ------------------------------ Switching Mode ------------------------------" >> ${dir_ccs}/mcss.log
echo "[----] TasKGen 2 (v1.2) - The New Mugino Job Manager!" >> ${dir_ccs}/mcss.log
if [ ${injectmode} = "inj" ]; then
echo "[TKG2] >> This is a inject! the current job is on hold!" >> ${dir_ccs}/mcss.log
fi
echo "[TKG2] >> Doing some math.." >> ${dir_ccs}/mcss.log
project_totalnum=0
project_tempassnum=0
project_totalnum=$(ls -d */ 2> /dev/null | wc -l)
single_totalnum=$(ls *.* 2> /dev/null | wc -l)
echo "[TKG2] >> Projects Found: ${project_totalnum} / Single Items Found: ${single_totalnum}" >> ${dir_ccs}/mcss.log
echo "[TKG2] >> Geneating projects and jobs..." >> ${dir_ccs}/mcss.log
if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
for dirl1 in */ ; do
	echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${dir_ccs}/mcss.log
	echo "[TKG2] >> Project: ${dirl1}" >> ${dir_ccs}/mcss.log
	project_tempassnum=$(( project_tempassnum + 1 ))
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
			Get_Data_File2Pross "${3}/${dirl1}${dirl2}${dirl3}" "${4}/${dirl1}${dirl2}${dirl3}" "${filedl3}" $1 $2 "${dirl1}" $project_tempassnum
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
		Get_Data_File2Pross "${3}/${dirl1}${dirl2}" "${4}/${dirl1}${dirl2}" "${filedl2}" $1 $2 "${dirl1}" $project_tempassnum
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
	Get_Data_File2Pross "${3}/${dirl1}" "${4}/${dirl1}" "${filedl1}" $1 $2 "${dirl1}" $project_tempassnum
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
Get_Data_File2Pross "${3}/" "${4}/" "${filedl0}" $1 $2 "N/A" $project_tempassnum
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
if [ ${injectmode} = "inj" ]; then
echo "[MMRT] >>> This is a inject! the current job is on hold!" >> ${dir_ccs}/mcss.log
fi
#Init Values
if [ ${injectmode} = "inj" ]; then
ijcurrentitem=0
#Calc total items
ijtotalitems=$(wc -l < ${dir_ccs}/inject.taskmgr.projob)
iji=0
pres="0"
else
currentitem=0
#Calc total items
totalitems=$(wc -l < ${dir_ccs}/taskmgr.projob)
i=0
pres="0"
fi

# Item Loop
if [ ${injectmode} = "inj" ]; then
{
echo "Injection Mode is not implimented yet! Job ignored"
}

else
##Non Inject mode
{
while [ $currentitem -lt $totalitems ]
do
currentitem=$(( currentitem + 1 ))
#Get Line for item to do
item="$(head -1 ${dir_ccs}/taskmgr.projob)"
#Get I/O and Filename(and with no ext)
item_in="$(awk -F : '{print $1}' < <(echo $item))"
item_out="$(awk -F : '{print $2}' < <(echo $item))"
item_filename="$(awk -F : '{print $3}' < <(echo $item))"
item_filename_out="$(echo ${item_filename} | cut -d '.' -f1)"
# Get Mode
item_mode=$(awk -F : '{print $4}' < <(echo $item))
# Get Settings and determin commnd line options
item_settings=$(awk -F : '{print $5}' < <(echo $item))
if [ $item_settings = 1 ]; then
	prossmode="noise_scale -noise_level 1"
	settingstext="${item_mode}x+NR"
fi
if [ $item_settings = 0 ]; then
	prossmode="scale"
	settingstext="${item_mode}x"
fi
if [ $item_settings = 2 ]; then
	prossmode="noise -noise_level 1"
	settingstext="NR"
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



# Run EPH then STD
if [ $item_prepross = 1 ]; then
cd "${dir_emph_blocks}/in"
echo "[MMRT] >>>> EMPH ${item_filename_out} ${item_dimen} ${item_size} [${settingstext}]" >> ${dir_ccs}/mcss.log
# Cut file by given grid
echo "[EMPH] >>>> Prepareing ${item_emphgrid} grid..." >> ${dir_ccs}/mcss.log
convert "${item_in}${item_filename}" -crop ${item_emphgrid}@ +repage +adjoin "emo_block_%d"
totalblocks="$(ls emo_block_* | wc -l)"
currentblock=1
#break
echo "[Meltdowner] >>>> Running Meltdowner on blocks..." >> ${dir_ccs}/mcss.log
for block in emo_block_*
do
cd  /opt/mugino-css/waifu2x/
if [ $item_mode = 2 ]; then
th waifu2x.lua -m ${prossmode} -i "${dir_emph_blocks}/in/${block}"  -o "${dir_emph_blocks}/out/${block}.png"  &>> ${dir_ccs}/mcss.log
fi
if [ $item_mode = 4 ]; then
th waifu2x.lua -m ${prossmode} -i "${dir_emph_blocks}/in/${block}"  -o "${dir_ccs}/4xdata.png"  &>> ${dir_ccs}/mcss.log
echo "[WARN!] >>>> 4x Mode is not completely ready, EMPH is not setup to check the output" >> ${dir_ccs}/mcss.log
th waifu2x.lua -m ${prossmode} -i "${dir_ccs}/4xdata.png"  -o "${dir_emph_blocks}/out/${block}.png"  &>> ${dir_ccs}/mcss.log
rm "${dir_ccs}/4xdata.png"
fi
currentblock=$(( currentblock + 1 ))
done
cd "${dir_emph_blocks}/out"
# If there is more then 9, rename them
if [ ${item_emphgrid} != "3x3" ]
then
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
montage -mode concatenate -tile ${item_emphgrid} emo_block_* "${item_out}${item_filename_out}(MCSS-${settingstext}).png"
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
if [ $item_mode = 2 ]; then
th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${dir_ccs}/mcss.log
fi
if [ $item_mode = 4 ]; then
th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${dir_ccs}/4xdata.png"  &>> ${dir_ccs}/mcss.log
th waifu2x.lua -m ${prossmode} -i "${dir_ccs}/4xdata.png"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${dir_ccs}/mcss.log
rm "${dir_ccs}/4xdata.png"
fi
fi
if [ i = 0 ]
then
pres=$(( 100*(1)/totalitems ))
else
pres=$(( 100*(++i)/totalitems ))
fi

echo $item &>> ${dir_ccs}/taskmgr_bk.projob
sed -i '1d' ${dir_ccs}/taskmgr.projob

done
}

fi
echo "[TKG2] >> Job is complete" >> ${dir_ccs}/mcss.log
}


## EMPH Grid calculator
# Input(s): File (Piped String (UUID.mcss))
# Outputs (s): Piped String "Grid Size (#x#)"
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
injectmode="no"
maxinpuuseage=0
maxinputrse=0
# Define Main Back Title and GPU Name
mastertitle="Mugino CUDA Super Scaler v2.41_25-10-2015"
gpuname="$(nvidia-smi -q | grep "Product Name " | cut -c 39-)"
gpucores="$(/cuda/NVIDIA_CUDA-7.5_Samples/1_Utilities/deviceQuery/deviceQuery | grep "CUDA Cores")"

if [ $# -lt 3 ]; then
echo "Missing options, Expecting 3 or 4"
echo "Usage: /dir/input /dir/output 2|4|2nr|4nr|nr [####]"
echo "		 <Input> <Output> <Mode, 2x or 4x, add nr for Noise Reduction> [Files must be smaller then X]"
echo "Edit the top of this file to set the scripts directory, temp locations,"
echo "EMPH's Trigger, and where the injects folder is located"
exit 1
fi
if [ $# -eq 3 ]; then
echo "${mastertitle}"
fi
if [ $# -eq 4 ]; then
echo "${mastertitle}"
echo "Input must be smaller then $4"
maxinpuuseage=1
maxinputrse=$4
fi
if [ $# -gt 4 ]; then
echo "To many options, Expecting 3 or 4"
echo "Usage: /dir/input /dir/output 2|4|2nr|4nr|nr [####]"
echo "		 <Input> <Output> <Mode, 2x or 4x, add nr for Noise Reduction> [Files must be smaller then X]"
echo "Edit the top of this file to set the scripts directory, temp locations,"
echo "EMPH's Trigger, and where the injects folder is located"
exit 1
fi
################################### init vars ###################################

dir_master_in="${1}"
dir_master_out="${2}"
oprtan0=""

# Make Temp Dirs
export dir_emph_blocks="${dir_tmp}/mcss/blks"
[ -d "${dir_master_out}" ] || mkdir -p "${dir_master_out}/"
[ -d "${dir_master_in}" ] || mkdir -p "${dir_master_in}/"
[ -d "${dir_emph_blocks}/in" ] || mkdir -p "${dir_emph_blocks}/in/"
[ -d "${dir_emph_blocks}/out" ] || mkdir -p "${dir_emph_blocks}/out/"
echo "[CORE] > Getting dir's ready..." >> ${dir_ccs}/mcss.log
echo "" >> ${dir_ccs}/mcss.log
echo "" >> ${dir_ccs}/mcss.log
echo "----- $(date) -------------------------------------------------------------" >> ${dir_ccs}/mcss.log
echo "${mastertitle}" >> ${dir_ccs}/mcss.log
echo "Loading core..." >> ${dir_ccs}/mcss.log
echo "[CORE] > Proccesser Card = ${gpuname}" >> ${dir_ccs}/mcss.log
echo "[CORE] > Proccesser Card Cores = ${gpucores}" >> ${dir_ccs}/mcss.log

if [ $3 = "2" ]; then
oprtan0="2 0"
elif [ $3 = "4" ]; then
oprtan0="4 0"
elif [ $3 = "2nr" ]; then
oprtan0="2 1"
elif [ $3 = "4nr" ]; then
oprtan0="4 1"
elif [ $3 = "nr" ]; then
echo "Mode is not implemted yet!"
exit 1
else
echo "Option not correct"
exit 1
fi

Runtime_Core_TasKGen $oprtan0 "${dir_master_in}" "${dir_master_out}"
Runtime_Core_WaifuCSS