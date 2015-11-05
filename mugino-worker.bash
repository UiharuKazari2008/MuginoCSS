#!/bin/bash
#
# Mugino CUDA Super Scaler for *nix
#
if [ $# -lt 1 ]; then echo "ABORT! You must use the Mugino Orchestrator to run this task or your versions dont match"; exit 1; fi
if [ $# -gt 1 ]; then echo "ABORT! You must use the Mugino Orchestrator to run this task or your versions dont match"; exit 1; fi
CurrentCommit="MCSS-IPPvCommit-9c4ce55d-be5e-4411-987a-d1db09127f9a"
WhoWasIt=0
WhoWasIt="$(awk -F : '{print $1}' < <(echo "${1}"))"
if [ $WhoWasIt != $CurrentCommit ]; then echo "ABORT! You must use the Mugino Orchestrator to run this task or your versions dont match"; exit 1; fi
SET_MODE_EXEC="$(awk -F : '{print $2}' < <(echo "${1}"))"
SET_MODE_INJ="$(awk -F : '{print $3}' < <(echo "${1}"))"
SET_MODE_SCALE="$(awk -F : '{print $4}' < <(echo "${1}"))"
SET_MODE_NR="$(awk -F : '{print $5}' < <(echo "${1}"))"
SET_VAL_MAXINRES="$(awk -F : '{print $6}' < <(echo "${1}"))"
SET_MODE_KIFR="$(awk -F : '{print $7}' < <(echo "${1}"))"
SET_MODE_CPIN="$(awk -F : '{print $8}' < <(echo "${1}"))"
SET_VAL_EMPH_TRIG="$(awk -F : '{print $9}' < <(echo "${1}"))"
VAL_DIR_MASTER_IN="$(awk -F : '{print $10}' < <(echo "${1}"))"
VAL_DIR_MASTER_OUT="$(awk -F : '{print $11}' < <(echo "${1}"))"
VAL_DIR_INJECT_IN="$(awk -F : '{print $12}' < <(echo "${1}"))"
VAL_DIR_CSS="$(awk -F : '{print $13}' < <(echo "${1}"))"
VAL_DIR_TEMP="$(awk -F : '{print $14}' < <(echo "${1}"))"
VAL_DIR_CPIN="$(awk -F : '{print $15}' < <(echo "${1}"))"
VAL_TOTAL_PROJ=0
VAL_TOTAL_SITM=0
mastertitle="Mugino CSS v2.71_29-10-2015"
gpuname="$(nvidia-smi -q | grep "Product Name " | cut -c 39-)"
gpucores="$(/cuda/NVIDIA_CUDA-7.5_Samples/1_Utilities/deviceQuery/deviceQuery | grep "CUDA Cores")"

RT_TGKFW-F2P()
{
	#Get HxW
	hf=$(identify -format "%h" "${1}${3}" 2>> ${VAL_DIR_CSS}/mcss.log)
	wf=$(identify -format "%w" "${1}${3}" 2>> ${VAL_DIR_CSS}/mcss.log)
	mf=$(identify -format "%m" "${1}${3}" 2>> ${VAL_DIR_CSS}/mcss.log)
	#Find longest edge
	if [ $hf -ge $wf ] 2>> ${VAL_DIR_CSS}/mcss.log; then
		le_res=$hf
		se_res=$wf
	else
		le_res=$wf
		se_res=$hf
	fi
	#Check if Inkect
	if [ ${SET_MODE_INJ} = 1 ]; then
		# If file falls within rangle run EMPH
		if [ $le_res -ge $SET_VAL_EMPH_TRIG ] 2>> ${VAL_DIR_CSS}/mcss.log; then
			#Mark for EMPH
			echo "[TKG2] 		INJECT-EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(CALC_CROP $le_res):${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):1" 1>> ${VAL_DIR_CSS}/inject.projob
		else
			# Mark for normal
			echo "[TKG2] 		INJECT-STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
			echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):1" 1>> ${VAL_DIR_CSS}/inject.projob
		fi
	# If its not a Inject do this
	else
		# Does it not use Max Input Size filtering
		if [ $SET_VAL_MAXINRES = 0 ]; then
			# If file falls within rangle run EMPH
			if [ $le_res -ge $SET_VAL_EMPH_TRIG ] 2>> ${VAL_DIR_CSS}/mcss.log; then
				#Mark for EMPH
				echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(CALC_CROP $le_res):${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${VAL_DIR_CSS}/taskmgr.projob
			else
				# Mark for normal
				echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
				echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${VAL_DIR_CSS}/taskmgr.projob
			fi
		# Max Input Size filtering
		else
			if [ $le_res -le $SET_VAL_MAXINRES  ]; then
				# If file falls within rangle run EMPH
				if [ $le_res -ge $SET_VAL_EMPH_TRIG ] 2>> ${VAL_DIR_CSS}/mcss.log; then
					#Mark for EMPH
					echo "[TKG2] 		EMPH -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
					echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:EMPH-$(CALC_CROP $le_res):${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${VAL_DIR_CSS}/taskmgr.projob
				else
					# Mark for normal
					echo "[TKG2] 		STD -> ${hf}x${wf} / ${mf} / ${3}" >> ${VAL_DIR_CSS}/mcss.log
					echo "${1}:${2}:${3}:${4}:${5}:${6}:${7}:STD-X:${hf}:${wf}:${le_res}:${mf}:$(du -sh "${1}${3}" | cut -c -4 | sed -e 's/^[ \t]*//'):0" 1>> ${VAL_DIR_CSS}/taskmgr.projob
				fi
			fi
		fi
	fi
	##### Input:Output:File:Mode:NR:Project:ProjectNum:Preproccess > projob file
}

RT_TGKFW()
{
	cd "${3}"
	echo "[CORE] ------------------------------ Switching Mode ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
	echo "[----] TasKGen 2 (v1.2) - The New Mugino Job Manager!" >> ${VAL_DIR_CSS}/mcss.log
	if [ ${SET_MODE_INJ} = 1 ]; then
		echo "[TKG2] >> This is a inject! the current job is on hold!" >> ${VAL_DIR_CSS}/mcss.log
	fi
	echo "[TKG2] >> Doing some math.." >> ${VAL_DIR_CSS}/mcss.log
	VAL_TOTAL_PROJ=$(ls -d */ 2> /dev/null | wc -l)
	VAL_TOTAL_SITM=$(ls ./*.* 2> /dev/null | wc -l)
	echo "[TKG2] >> Projects Found: ${VAL_TOTAL_PROJ} / Single Items Found: ${VAL_TOTAL_SITM}" >> ${VAL_DIR_CSS}/mcss.log
	echo "[TKG2] >> Geneating projects and jobs..." >> ${VAL_DIR_CSS}/mcss.log
	if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
		for dirl1 in */ ; do
			echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
			echo "[TKG2] >> Project: ${dirl1}" >> ${VAL_DIR_CSS}/mcss.log
			echo "[TKG2] >> Contex is now /${dirl1}" >> ${VAL_DIR_CSS}/mcss.log
			cd "${dirl1}"
			if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
				for dirl2 in */ ; do
					{
						cd "${dirl2}"
						if [ $(ls -d */ 2> /dev/null | wc -l) != 0 ]; then
							for dirl3 in */ ; do
								{
									cd "${dirl3}"
									if [ $(ls ./*.* 2> /dev/null | wc -l) != 0 ]; then
										echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
										echo "[TKG2] >> Contex is now /../../${dirl3}" >> ${VAL_DIR_CSS}/mcss.log
										for filedl3 in *.* ; do
											RT_TGKFW-F2P "${3}/${dirl1}${dirl2}${dirl3}" "${4}/${dirl1}${dirl2}${dirl3}" "${filedl3}" $1 $2 "${dirl1}" $6
										done
										[ -d "${4}/${dirl1}${dirl2}${dirl3}" ] || mkdir -p "${4}/${dirl1}${dirl2}${dirl3}"
										fi
									cd .. 2> /dev/null
								}
							done
						fi
							{
								if [ $(ls ./*.*  2> /dev/null | wc -l) != 0 ]; then
									echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
									echo "[TKG2] >> Contex is now /../${dirl2}" >> ${VAL_DIR_CSS}/mcss.log
									for filedl2 in *.* ; do
										RT_TGKFW-F2P "${3}/${dirl1}${dirl2}" "${4}/${dirl1}${dirl2}" "${filedl2}" $1 $2 "${dirl1}" $6
									done
									[ -d "${4}/${dirl1}${dirl2}" ] || mkdir -p "${4}/${dirl1}${dirl2}"
								fi
								cd .. 2> /dev/null
							}
					}
				done
			fi
			{
				if [ $(ls ./*.* 2> /dev/null | wc -l) != 0 ]; then
					echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
					echo "[TKG2] >> Contex is now /${dirl1}" >> ${VAL_DIR_CSS}/mcss.log
					for filedl1 in *.* ; do
						RT_TGKFW-F2P "${3}/${dirl1}" "${4}/${dirl1}" "${filedl1}" $1 $2 "${dirl1}" $6
					done
					[ -d "${4}/${dirl1}" ] || mkdir -p "${4}/${dirl1}"
				fi
				cd .. 2> /dev/null
			}
		done
	fi
	if [ $(ls ./*.* 2> /dev/null | wc -l) != 0 ]; then
		echo "[TKG2] ------------------------------ Contex Changeing ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
		echo "[TKG2] >> Contex is now /" >> ${VAL_DIR_CSS}/mcss.log
		for filedl0 in *.* ; do
			RT_TGKFW-F2P "${3}/" "${4}/" "${filedl0}" $1 $2 "N/A" $6
		done
		[ -d "${4}" ] || mkdir -p "${4}"
	fi
}

RT_TGKFW-INJ()
{
	echo "[TKG2] >> Injecting items into current project..." >> ${VAL_DIR_CSS}/mcss.log
	curdir="$(pwd)"
	cd ${VAL_DIR_CSS}
	# Inject data at line 2
	sed -i '1r inject.projob' taskmgr.projob
	cd "$curdir"
	echo "[TKG2] >> Injection Complete, Wait till current item is complete." >> ${VAL_DIR_CSS}/mcss.log
}

RT_TGKFW-ADD()
{
	echo "[TKG2] >> Appending items into current project..." >> ${VAL_DIR_CSS}/mcss.log
	# Inject data at end of file
	cat "${VAL_DIR_CSS}/inject.projob" >> ${VAL_DIR_CSS}/taskmgr.projob
	echo "[TKG2] >> Append Complete, Wait till current item is complete." >> ${VAL_DIR_CSS}/mcss.log
}

RT_WORKER() 
{
	echo "[CORE] ------------------------------ Switching Mode ------------------------------" >> ${VAL_DIR_CSS}/mcss.log
	echo "[----] Mugino Meltdowner Runtime (v1.6)" >> ${VAL_DIR_CSS}/mcss.log
	# Item Loop
	{
		while [ $([[ -f ${VAL_DIR_CSS}/taskmgr.projob ]] && wc -l < ${VAL_DIR_CSS}/taskmgr.projob || echo 0) != 0 ]; do
			#Get Line for item to do
			item="$(head -1 ${VAL_DIR_CSS}/taskmgr.projob)"
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
			SET_MODE_INJ=$(awk -F : '{print $14}' < <(echo $item))
			# Run EPH then STD
			if [ $item_prepross = 1 ]; then
				cd "${VAL_DIR_TEMP}/in"
				echo "[MMRT] >>>> EMPH ${item_filename_out} ${item_dimen} ${item_size} [${settingstext}]" >> ${VAL_DIR_CSS}/mcss.log
				# Cut file by given grid
				echo "[EMPH] >>>> Prepareing ${item_emphgrid} grid..." >> ${VAL_DIR_CSS}/mcss.log
				convert "${item_in}${item_filename}" -crop ${item_emphgrid}@ +repage +adjoin "emo_block_%d" &>> ${VAL_DIR_CSS}/mcss.log
				currentblock=1
				#break
				echo "[Meltdowner] >>>> Running Meltdowner on blocks..." >> ${VAL_DIR_CSS}/mcss.log
				for block in emo_block_*; do
					cd  /opt/mugino-css/waifu2x/
					if [ $item_mode = 4 ]; then
						th waifu2x.lua -m ${prossmode} -i "${VAL_DIR_TEMP}/in/${block}"  -o "${VAL_DIR_CSS}/4xdata.png"  &>> ${VAL_DIR_CSS}/mcss.log
						echo "[WARN!] >>>> 4x Mode is not completely ready, EMPH is not setup to check the output" >> ${VAL_DIR_CSS}/mcss.log
						th waifu2x.lua -m ${prossmode} -i "${VAL_DIR_CSS}/4xdata.png"  -o "${VAL_DIR_TEMP}/out/${block}.png"  &>> ${VAL_DIR_CSS}/mcss.log
						rm "${VAL_DIR_CSS}/4xdata.png"
					else
						th waifu2x.lua -m ${prossmode} -i "${VAL_DIR_TEMP}/in/${block}"  -o "${VAL_DIR_TEMP}/out/${block}.png"  &>> ${VAL_DIR_CSS}/mcss.log
					fi
					currentblock=$(( currentblock + 1 ))
				done
				cd "${VAL_DIR_TEMP}/out"
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
				echo "[EMPH] >>>> Compleing output..." >> ${VAL_DIR_CSS}/mcss.log
				montage -mode concatenate -tile ${item_emphgrid} emo_block_* "${item_out}${item_filename_out}(MCSS-${settingstext}).png" &>> ${VAL_DIR_CSS}/mcss.log
				# Remove old blocks from EMo
				rm emo_block_*
				cd "${VAL_DIR_TEMP}/in"
				rm emo_block_*
			fi
			# Run STD
			if [ $item_prepross = 0 ]; then
				# Run Scaler with input from the current mode
				echo "[Meltdowner] >>>> STD ${item_filename_out} ${item_dimen} ${item_size} [${settingstext}]" >> ${VAL_DIR_CSS}/mcss.log
				cd  /opt/mugino-css/waifu2x/
				if [ $item_mode = 4 ]; then
					th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${VAL_DIR_CSS}/4xdata.png"  &>> ${VAL_DIR_CSS}/mcss.log
					th waifu2x.lua -m ${prossmode} -i "${VAL_DIR_CSS}/4xdata.png"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${VAL_DIR_CSS}/mcss.log
					rm "${VAL_DIR_CSS}/4xdata.png"
				else
					th waifu2x.lua -m ${prossmode} -i "${item_in}${item_filename}"  -o "${item_out}${item_filename_out}(MCSS-${settingstext}).png"  &>> ${VAL_DIR_CSS}/mcss.log
				fi
			fi
			# Embed if required
			if [ $item_embed = 1 ]; then
				echo "[KIFR] >>> Embedding Input File..." >> ${VAL_DIR_CSS}/mcss.log
				stepic --encode --image-in="${item_out}${item_filename_out}(MCSS-${settingstext}).png" --data-in="${item_in}${item_filename}" --out="${item_out}${item_filename_out}(MCSS-${settingstext}+E).png" &>> ${VAL_DIR_CSS}/mcss.log
				[[ -f "${item_out}${item_filename_out}(MCSS-${settingstext}+E).png" ]] && rm "${item_out}${item_filename_out}(MCSS-${settingstext}).png"
			fi
			echo $item &>> ${VAL_DIR_CSS}/taskmgr_bk.projob
			sed -i '1d' ${VAL_DIR_CSS}/taskmgr.projob
		done
	}
	echo "[TKG2] >> Job is complete" >> ${VAL_DIR_CSS}/mcss.log
}

CALC_CROP() 
{
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

LOG_HEADER()
{
	echo "" >> ${VAL_DIR_CSS}/mcss.log
	echo "" >> ${VAL_DIR_CSS}/mcss.log
	echo "----- $(date) -------------------------------------------------------------" >> ${VAL_DIR_CSS}/mcss.log
	echo "${mastertitle}" >> ${VAL_DIR_CSS}/mcss.log
	echo "[CORE] > Proccesser Card = ${gpuname}" >> ${VAL_DIR_CSS}/mcss.log
	echo "[CORE] > Proccesser Card Cores = ${gpucores}" >> ${VAL_DIR_CSS}/mcss.log
	[ -d "${VAL_DIR_TEMP}/in" ] || mkdir -p "${VAL_DIR_TEMP}/in/"
	[ -d "${VAL_DIR_TEMP}/out" ] || mkdir -p "${VAL_DIR_TEMP}/out/"
}

if [ $SET_MODE_EXEC = "run" ]; then
	LOG_HEADER; echo "[CORE] Called as Prep-only Mode" >> ${VAL_DIR_CSS}/mcss.log
	rm ${VAL_DIR_CSS}/taskmgr.projob 2> /dev/null
	RT_TGKFW $SET_MODE_SCALE $SET_MODE_NR "${VAL_DIR_MASTER_IN}" "${VAL_DIR_MASTER_OUT}" $SET_MODE_CPIN $SET_MODE_KIFR
	RT_WORKER
	rm ${VAL_DIR_CSS}/taskmgr.projob 2> /dev/null
elif [ $SET_MODE_EXEC = "prep" ]; then
	LOG_HEADER; echo "[CORE] Called as Prep-only Mode" >> ${VAL_DIR_CSS}/mcss.log
	#Prepare Job file, useful if not running at that moment
	rm ${VAL_DIR_CSS}/taskmgr.projob 2> /dev/null
	RT_TGKFW $SET_MODE_SCALE $SET_MODE_NR "${VAL_DIR_MASTER_IN}" "${VAL_DIR_MASTER_OUT}" $SET_MODE_CPIN $SET_MODE_KIFR
elif [ $SET_MODE_EXEC = "p-run" ]; then
	LOG_HEADER; echo "[CORE] Called as Run Mode" >> ${VAL_DIR_CSS}/mcss.log
	RT_WORKER
	rm ${VAL_DIR_CSS}/taskmgr.projob 2> /dev/null
elif [ $SET_MODE_EXEC = "inject" ]; then
	# Inject items into the current job
	SET_MODE_INJ=1
	rm ${VAL_DIR_CSS}/inject.projob 2> /dev/null
	RT_TGKFW $SET_MODE_SCALE $SET_MODE_NR "${VAL_DIR_INJECT_IN}" "${VAL_DIR_MASTER_OUT}" $SET_MODE_CPIN $SET_MODE_KIFR
	RT_TGKFW-INJ
	rm ${VAL_DIR_CSS}/inject.projob 2> /dev/null
elif [ $SET_MODE_EXEC = "append" ]; then
	# Inject items into the current job
	SET_MODE_INJ=1
	rm ${VAL_DIR_CSS}/inject.projob 2> /dev/null
	RT_TGKFW $SET_MODE_SCALE $SET_MODE_NR "${VAL_DIR_INJECT_IN}" "${VAL_DIR_MASTER_OUT}" $SET_MODE_CPIN $SET_MODE_KIFR
	RT_TGKFW-ADD
	rm ${VAL_DIR_CSS}/inject.projob 2> /dev/null
elif [ $SET_MODE_EXEC = "recover" ]; then
	LOG_HEADER; echo "[CORE] Called as Image Recovery Mode" >> ${VAL_DIR_CSS}/mcss.log
	[ -d "${VAL_DIR_MASTER_OUT}/Recovery/" ] || mkdir -p "${VAL_DIR_MASTER_OUT}/Recovery/"
	cd "${VAL_DIR_MASTER_IN}"
	for inputfile in *.png; do stepic --decode --image-in="${VAL_DIR_MASTER_IN}/${inputfile}" --out="${VAL_DIR_MASTER_OUT}/Recovery/RECOVERED-${inputfile}" &>> ${VAL_DIR_CSS}/mcss.log; done
else
	echo "[PEBKAC] No Exec Mode was defined or was not correct, Abort"; exit 1
fi

if [ $SET_MODE_INJ = 1 ]; then echo "---------------------------------------------------------------------------" >> ${VAL_DIR_CSS}/mcss.log; fi
