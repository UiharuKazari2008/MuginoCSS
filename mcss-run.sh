#!/bin/bash

#
# Mugino CUDA Super Scaler for *nix
#

#########################################################################################################

## USER: Edit these for your system 

# Define Locations
## Main Input for Single File Job
export dir_master_in="/home/mugino/Input"
## Main Output for all jobs
export dir_master_out="/home/mugino/Output"
## Main Input for Batch Jobs
export dir_master_batch_in="/home/mugino/Batch"
## Log file location
export dir_ccs_log="/mnt/photostor0"
## Storage of temp files
export dir_tmp="/mnt/photostor0"
## What image size should triger EMPH? If you have more RAM you can make this higher
## This is the longest edge, in pixels. This must be a number, no text
var_emph_trigger="3000"


################################### init vars ###################################

# Define Main Back Title and GPU Name
mastertitle="Mugino CUDA Super Scaler v1.82_20-10-2015"
gpuname="$(nvidia-smi -q | grep "Product Name " | cut -c 39-)"
gpucores="$(/cuda/NVIDIA_CUDA-7.5_Samples/1_Utilities/deviceQuery/deviceQuery | grep "CUDA Cores")"



# Make Temp Dirs
export dir_emph_in="${dir_tmp}/mcss/input"
export dir_emph_out="${dir_tmp}/mcss/ouput"
export dir_emph_blocks="${dir_tmp}/mcss/blks"
export dir_emph_blocks_done="${dir_tmp}/mcss/blks-output"
export dir_emph_ocd="${dir_tmp}/mcss/xdata-emph"
export dir_std_ocd="${dir_tmp}/mcss/xdata-std"
export dir_std_in="${dir_tmp}/mcss/std/in"
export dir_std_out="${dir_tmp}/mcss/std/out"
export dir_css_in="${dir_tmp}/mcss/css"


# Check if Locations exixt, if not make them
[ -d "${dir_master_out}/unfiled" ] || mkdir -p "${dir_master_out}/unfiled"
[ -d "${dir_master_in}/2x" ] || mkdir -p "${dir_master_in}/2x/"
[ -d "${dir_master_batch_in}/2x" ] || mkdir -p "${dir_master_batch_in}/2x/"
[ -d "${dir_emph_in}/2x" ] || mkdir -p "${dir_emph_in}/2x/"
[ -d "${dir_emph_out}/2x" ] || mkdir -p "${dir_emph_out}/2x/"
[ -d "${dir_emph_blocks}/2x" ] || mkdir -p "${dir_emph_blocks}/2x/"
[ -d "${dir_emph_blocks_done}/2x" ] || mkdir -p "${dir_emph_blocks_done}/2x/"
[ -d "${dir_std_in}/2x" ] || mkdir -p "${dir_std_in}/2x/"
[ -d "${dir_std_out}/2x" ] || mkdir -p "${dir_std_out}/2x/"
[ -d "${dir_css_in}/2x" ] || mkdir -p "${dir_css_in}/2x/"

# Misc Var Init
totalitems=0

################################### Runtime ###################################

## Single Job Interface, Sort, Check, Run, Check, Run, Move (4x itter 1 skip)
# Input(s): Mode (2x, 4x, 6x, 8x); Finish (Move to M.Complete? 1 or 0); Project Name (No Project name = "nop")
# Outputs (s):
Runtime_Core_Job_Single()
{
# Is there files in the input?
totalitems="$(ls ${dir_master_in}/${1}/  | wc -l)"
if [ ${totalitems} != 0 ]; then
	# Make MCSS files
	#DataMgr_Rename ${1}
	# Sort Files
	DataMgr_Sort_MIn ${1}
	# Init Error count
	errorcount=1
	# Init Item Count
	currentitem=1
	# Calc numbers
	#emph_total_inn="$(ls "${dir_emph_in}/${1}/" | wc -l)"
	#std_total_inn="$(ls "${dir_std_in}/${1}/" | wc -l)"
	# Is there EMPH tasks?
	if [ ${emph_total_inn} != 0 ]; then
		# Run EMPH Runtime
		Runtime_Core_EMPHTaskMan ${1} "${3}"
	# There is no files, tick coutner
	else
		errorcount=$((++errorcount))
	fi
	# Is there Standard tasks?
	if [ ${std_total_inn} != 0 ]; then
		# Run STD Runtime
		Runtime_Core_STD ${1} "${3}"
	# There are no files, tick counter
	else
		errorcount=$((++errorcount))
	fi
	# If both tasks fail then complain that there are no files to proccess, maybe the sorted content failed to be accessed?
	if [ ${errorcount} = 3 ]; then
		error_colors
		dialog --colors --title "\Zb[ Data Manager - IO_FAULT ]\Zn" --infobox "No Data was found in any of runtime inputs\n\
This could mean that:\n\
1. You did not define the dir_<runtime>_in or out var \n\
2. The defined values are not readable or denied access\n\
Please correct this issue and restart MCSS \n\n\
Runtime - STD: ${dir_std_in} \n\
Runtime - EMPH: ${dir_emph_in}" 10 60
		reset_colors
		sleep 4
	fi
		# Clean out input data
		rm ${dir_std_in}/${1}/*
		rm ${dir_emph_in}/${1}/*
	# 
	if [ ${2} -eq 1 ]; then
		mv ${dir_emph_out}/${1}/* ${dir_master_out}
		mv ${dir_std_out}/${1}/* ${dir_master_out}
	fi
else
	# If there is no files then error out
	error_colors
	dialog --colors --title "\Zb[ No Input ]\Zn" --infobox "No images are in the input folder for this job\n\
Please put your data in the folder and run again.\n\nFolder: ${dir_master_in}" 6 54
	reset_colors
	sleep 2
fi
}

Runtime_Core_Job_Multi()
{
# Clean up output and temp
DataMgr_Move_Unfiled
DataMgr_Clean_Temp
# Change contex to master batch dir
cd "${dir_master_batch_in}/${1}"
totalprojects="$(ls "${dir_master_batch_in}/${1}/"  | wc -l)"
currentproject=1
dialog --colors --title "\Zb[ Mugino Data Inspector ]\Zn" --infobox "Preparing Projects...\n\
\ZbProjects:\Zn ${totalprojects}" 4 46
sleep 2
if [ $(ls "${dir_master_batch_in}/${1}/"  | wc -l) != 0 ]; then
for d in */ ; do
  {
  if [ $(ls "${d}" | wc -l) != 0 ]; then
  cd "${d}"
  {
  for f in *.* ; do
  mv "${f}" "${dir_master_in}/${1}/${f}"
  done
  }
  #cd ..
  #rmdir "${d}"
  Runtime_Core_Job_Single ${1} 0 "${d}"
  currentproject="$((currentproject + 1))"
  mkdir "${dir_master_out}/$d"
  cd "${dir_master_out}/$d"
  mv ${dir_emph_out}/${1}/*.* ./
  mv ${dir_std_out}/${1}/*.* ./
  cd "${dir_master_batch_in}/${1}"
  fi
  }
done
else
	error_colors
	dialog --colors --title "\Zb [ No Input ] \Zn" --infobox "No projects are in the input folder for this job\n\
Please put your data in the folder and run again.\n\nFolder: ${dir_master_batch_in}" 6 54
	reset_colors
sleep 2
fi
}

## Run Standrard Runtime
# Input(s): 
# Outputs (s): 
Runtime_Core_STD() 
{
dialog  --colors --title "\Zb [ Data Manager ] \Zn" --infobox "Preparing Data..." 3 30
cd "${dir_std_in}/${1}"
# get number of files
n=$(ls * | wc -l)
# Progress Display that has the runtime object in it
mugino_colors
dialog  --colors --backtitle "$mastertitle" --title "\Zb [ Mugino Meltdowner ] \Zn" --gauge "Waiting for init pipeline...  \n\
Processor Card Temp: $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)" 15 75 < <(
# set 0
i=0
pres="0"
prev="nopipe"
# for each file, make display and run it
for file in *.*;
do
{
if [ "${2}" != "nop" ]
then
porject_name="${2} ( ${currentproject} / ${totalprojects} )"
else
porject_name="Single Item(s)"
fi
}
# pipe display
echo "XXX"
echo "Project: $porject_name"
echo "File: $file ( ${currentitem} / ${totalitems} )"
echo " "
echo " ---- File Info ----"
echo "Current: "$(identify -format "%w x %h (%m " "${dir_std_in}/${1}/${file}")$(du -sh "${dir_std_in}/${1}/${file}" | cut -c -4 | sed -e 's/^[ \t]*//')") -> Waifu2x (${1})"
echo "Last: "$(Disp_MM_LastFile "${prev}" ${1} "${dir_std_in}" "${dir_std_out}")
echo " -------------------"
echo " "
echo "Processor Card: $gpuname @ $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)"
echo "XXX"
echo "$pres"
#do the task
Runtime_Core_WaifuCSS ${1} "${dir_std_in}" "${dir_std_out}" "${file}"
# Update XX#% var
{
if [ i = 0 ]
then
pres=$(( 100*(1)/n ))
else
pres=$(( 100*(++i)/n ))
fi
}
prev="$file"
currentitem=$(( currentitem + 1 ))
done
dialog --clear
)
reset_colors
}

## Run EMPH Runtime
# Input(s): Mode (Piped String)
# Outputs (s): File data-output (PNG File, No contex)
Runtime_Core_EMPHTaskMan() 
{
# Change contex
cd "${dir_emph_in}/${1}"
# For each file, run EM, then run CSS, then run PH, then move to output
for file1 in *.*;
do
{
# Move file to out of contex input file
mv "${dir_emph_in}/${1}/${file1}" "${dir_emph_ocd}"
# Define Crop Grid, Call function and use output as var
emph_crop=$(Get_Data_CropLvl "${dir_emph_ocd}")
# Run EMo
emph_colors
dialog  --colors --title " [ EMPH Task Control (Task 1/3) ] " --infobox "Processing Data @ ${emph_crop}..." 3 46
Runtime_EMPH_Emo ${emph_crop} ${1}
reset_colors
# Change contex
cd "${dir_emph_blocks}/${1}"
# For each block, run CCS
n=$(ls emo_block* | wc -l)
# Progress Display that has the runtime object in it
mugino_colors
dialog  --colors --backtitle "$mastertitle" --title " [ Mugino Meltdowner (from EMPH Task) ] " --gauge "Waiting for init pipeline... \n\
Processor Card Temp: $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)" 16 75 < <(
# set 0
i=0
pres="0"
prev="nopipe"
# for each file, make display and run it
for filexx in * ;
do
{
if [ "${2}" != "nop" ]
then
porject_name="(EMPH Task) ${2} ( ${currentproject} / ${totalprojects} )"
else
porject_name="(EMPH Task) Single Item"
fi
}
# pipe display
echo "XXX"
echo "Project: $porject_name"
echo "Parent File: $file1 ( ${currentitem} / ${totalitems} )"
echo "Block: $filexx from ${emph_crop} file grid"
echo " "
echo " ---- File Info ----"
echo "Current: "$(identify -format "%w x %h (%m " "${dir_emph_blocks}/${1}/${filexx}")$(du -sh "${dir_emph_blocks}/${1}/${filexx}" | cut -c -4 | sed -e 's/^[ \t]*//')") -> MCSS Runtime"
echo "Last: "$(Disp_MM_LastFile $prev ${1} "${dir_emph_blocks}" "${dir_emph_blocks_done}")
echo " -------------------"
echo " "
echo "Processor Card: $gpuname @ $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)"
echo "XXX"
echo "$pres"
#do the task
Runtime_Core_WaifuCSS ${1} "${dir_emph_blocks}" "${dir_emph_blocks_done}" ${filexx}
# Calc XX#% var
{
if [ i = 0 ]
then
pres=$(( 100*(1)/n ))
else
pres=$(( 100*(++i)/n ))
fi
}
prev=$filexx

done
dialog --clear
)
reset_colors
# Run PHoenix
emph_colors
dialog  --colors --title " [ EMPH Task Control (Task 3/3) ] " --infobox "Processing Data..." 3 46
Runtime_EMPH_Phoenix $emph_crop ${1} $file1
dialog  --colors --title " [ EMPH Task Control (Task 3/3) ] " --infobox "Processing Data... COMPLETE!" 3 46
reset_colors
sleep 2
}
currentitem=$(( currentitem + 1 ))
done
}

################################### Data Manager ###################################

## Rename Items to UUID (for file name problems)
# Input(s): Mode
# Outputs (s): 
# DataMgr_Rename() 
# {
# dialog --title " [ Mugino Data Control ] " --infobox "Preparing Input..." 3 46
# cd "${dir_master_in}/${1}/"
# for files in *
# do
#   mv "$files" ./$(uuid).mcss;
# done
# dialog --title " [ Mugino Data Control ] " --infobox "Preparing Input... DONE" 3 46
# sleep 1
# }

## Input Data Sort, find data that needs EMPH, if true sort it for it
# Input(s):
# Outputs (s): 
DataMgr_Sort_MIn() 
{
# Calc numbers
master_total_inn="$(ls "${dir_master_in}/${1}/" | wc -l)"
cd "${dir_master_in}/${1}/"
dialog  --colors --title " [ Mugino Data Inspector ] " --infobox "Preparing Data...\n\
Items: ${master_total_inn} ( Waiting on EMPH... )" 4 46
enumm=1
for file in *.*;
do
{
#Get HxW
hx=$(identify -format "%h" "${dir_master_in}/${1}/${file}")
wx=$(identify -format "%w" "${dir_master_in}/${1}/${file}")
#Find longest edge
if [ $hx -ge $wx ]
then
hig=$hx
else
hig=$wx
fi
# If file is over 3000px (longest edge) then move it to EMPH input
if [ $hig -ge $var_emph_trigger ]
then
	#Move to be procced by EMPH
	mv "${dir_master_in}/${1}/${file}" "${dir_emph_in}/${1}"
fi
}
done
# Move everything else (under 3000px) to input that will be done later
for file in *.*;
do
mv "${dir_master_in}/${1}/${file}" "${dir_std_in}/${1}" &> /dev/null
done
# Calc numbers
emph_total_inn="$(ls "${dir_emph_in}/${1}/" | wc -l)"
std_total_inn="$(ls "${dir_std_in}/${1}/" | wc -l)"
dialog  --colors --title " [ Mugino Data Inspector ] " --infobox "Preparing Data...\n\
Items: ${std_total_inn} ( ${emph_total_inn} will use EMPH )" 4 46
sleep 1
}

## Clean up temp directorys
# Input(s): None
# Outputs (s): None
DataMgr_Clean_Temp() 
{
dialog  --colors --title " [ Data Manager ] " --infobox "Cleaning up..." 3 30
rm -R "${dir_emph_in}/*"
rm -R "${dir_emph_out}/*"
rm -R "${dir_emph_blocks}/*"
rm -R "${dir_emph_blocks_done}/*"
rm -R "${dir_emph_ocd}"
rm -R "${dir_std_in}/*"
rm -R "${dir_std_out}/*"
rm -R "${dir_css_in}/*"
dialog  --colors --title " [ Data Manager ] " --infobox "Files are removed" 3 30
sleep 1
}

## Delete All Files
DataMgr_Clean_All() 
{
dialog  --colors --title " [ Data Manager ] " --infobox "Cleaning up..." 3 30
rm -R "${dir_emph_in}/*"
rm -R "${dir_emph_out}/*"
rm -R "${dir_emph_blocks}/*"
rm -R "${dir_emph_blocks_done}/*"
rm -R "${dir_emph_ocd}"
rm -R "${dir_std_in}/*"
rm -R "${dir_std_out}/*"
rm -R "${dir_css_in}/*"
rm -R "${dir_master_batch_in}/*"
rm -R "${dir_master_in}/*"
rm -R "${dir_master_out}/*"
dialog  --colors --title " [ Data Manager ] " --infobox "Files are removed" 3 30
sleep 1
}

# Move unfiled files to the unfiled folder
DataMgr_Move_Unfiled()
{
dialog  --colors --title " [ Data Manager ] " --infobox "Moving unfiled images..." 3 30
if [ $(ls "${dir_master_out}/*.*" | wc -l) != 0 ]; then
    mv "${dir_master_out}/*.png" "${dir_master_out}/unfiled"
    dialog --title " [ Data Manager ] " --infobox "Moved to /unfiled" 3 30
else
dialog  --colors --title " [ Data Manager ] " --infobox "Nothing to move" 3 30
fi
sleep 1
}

################################### Infomation ###################################

## EMPH Grid calculator
# Input(s): File (Piped String (UUID.mcss))
# Outputs (s): Piped String "Grid Size (#x#)"
Get_Data_CropLvl() {
#Get File Info
hx=$(identify -format "%h" "${1}")
wx=$(identify -format "%w" "${1}")
#Find longest edge
if [ $hx -ge $wx ]
then
hig=$hx
else
hig=$wx
fi
#Get grid size
if [ $hig -le 3000 ]
then
echo "3x3"
break
fi
if [ $hig -le 7000 ]
then
echo "4x4"
break
else
if [ $hig -le 9000 ]
then
echo "5x5"
break
else
if [ $hig -le 14000 ]
then
echo "6x6"
break
else
if [ $hig -le 17000 ]
then
echo "7x7"
break
else
if [ $hig -le 20000 ]
then
echo "8x8"
break
else
if [ $hig -le 23000 ]
then
echo "9x9"
break
else
if [ $hig -le 27000 ]
then
echo "10x10"
break
else
if [ $hig -le 30000 ]
then
echo "11x11"
break
else
if [ $hig -le 32000 ]
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


## Creates previous file data infomation
# Input(s): Mode (Piped String), Function , Previous File (Piped String (UUID.mcss))
# Outputs (s): Piped text
Disp_MM_LastFile()
{
if [ "${1}" != "nopipe" ]
then
echo $(identify -format "%w x %h (%m " "${3}/${2}/${1}")$(du -sh "${3}/${2}/${1}" | cut -c -4 | sed -e 's/^[ \t]*//')") -> "$(identify -format "%w x %h (%m " "${4}/${2}/${1}.png")$(du -sh "${4}/${2}/${1}.png" | cut -c -4 | sed -e 's/^[ \t]*//')")"
# in "$(tail -1 /opt/mugino-css/css_log.log | sed -e 's/^[ \t]*//')
fi
if [ "${1}" = "nopipe" ]
then
echo " "
fi
}


################################### MCSS ###################################

## MCSS Runtime (Scale Mode)
# Input(s): File (Piped String (MCSS ? Image, Out of contex), Mode (Piped String)
# Outputs (s): File (Piped String (MCSS PNG Image, No contex)
Runtime_Core_WaifuCSS() 
{
# Go to library
if [ ${cssmode} = 1 ]; then
	prossmode="noise_scale -noise_level 1"
fi
if [ ${cssmode} = 0 ]; then
	prossmode="scale"
fi
cd  /opt/mugino-css/waifu2x/
# Run Scaler with input from the current mode
th waifu2x.lua -m ${prossmode} -i  "${2}/${1}/${4}" -o  "${3}/${1}/${4}.png" &>> $dir_ccs_log/css_log.log
}


################################### EMPH ###################################

## EMo: Cuts file up into grid to account for low resources
## Get the pun.....emo....cut.....
# Input(s): Crop (Piped String (#x#)), ${dir_master_out}/emph/data-input (PNG File, Out of contex)
# Outputs (s): File data-output (PNG File, No contex)
Runtime_EMPH_Emo() 
{
cd "${dir_emph_blocks}/${2}"
# Cut file by given grid
convert "${dir_emph_ocd}" -crop ${1}@ +repage +adjoin "emo_block_%d"
# Remove input file
rm "${dir_emph_ocd}"
}

## PHoenix: Recompiles the grid for final output
## Get the pun.....phoenix....recontructs.....
# Input(s): None
# Outputs (s): ${dir_master_out}/emph/data-output (PNG File, No contex)
Runtime_EMPH_Phoenix() 
{
cd "${dir_emph_blocks_done}/${2}"
# If there is more then 9, rename them
if [ ${1} != "3x3" ]
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
montage -mode concatenate -tile ${1} emo_block_* "${dir_emph_ocd}"
mv "${dir_emph_ocd}" "${dir_emph_out}/${2}/${3}.png"
# Remove old blocks from EMo
rm emo_block_*
cd "${dir_emph_blocks}/${2}"
rm emo_block_*
}

################################### Menus and Dialogs ###################################

reset_colors()
{
echo "use_shadow = OFF
use_colors = ON
screen_color = (WHITE,DEFAULT,OFF)
dialog_color = (BLACK,WHITE,OFF)
title_color = (BLACK,WHITE,OFF)
border_color = (BLACK,WHITE,OFF)

button_active_color = (WHITE,BLUE,OFF)
button_key_active_color = (WHITE,BLUE,OFF)
button_label_active_color = (WHITE,BLUE,OFF)

button_inactive_color = (BLACK,WHITE,OFF)
button_key_inactive_color = (RED,WHITE,OFF)
button_label_inactive_color = (BLACK,WHITE,OFF)

inputbox_color = (BLACK,WHITE,OFF)
inputbox_border_color = (BLACK,BLACK,OFF)

searchbox_color = (WHITE,BLACK,OFF)
searchbox_title_color = (GREEN,BLACK,OFF)
searchbox_border_color = (WHITE,BLACK,OFF)

position_indicator_color = (BLUE,WHITE,OFF)

menubox_color = (BLACK,WHITE,OFF)
menubox_border_color = (BLACK,WHITE,OFF)

item_color = (BLACK,WHITE,OFF)
item_selected_color = (BLACK,BLUE,OFF)

tag_color = (BLACK,WHITE,OFF)
tag_selected_color = (BLACK,BLUE,OFF)
tag_key_color = (BLUE,WHITE,OFF)
tag_key_selected_color = (BLACK,BLUE,OFF)

check_color = (WHITE,BLACK,OFF)
check_selected_color = (BLACK,BLUE,OFF)

uarrow_color = (BLUE,BLACK,OFF)
darrow_color = (BLUE,BLACK,OFF)

itemhelp_color = (BLACK,WHITE,OFF)

form_active_text_color = (BLACK,BLUE,OFF)
form_text_color = (WHITE,BLACK,OFF)
form_item_readonly_color = (BLACK,WHITE,OFF)" > ~/.dialogrc
}

error_colors()
{
sed -i -e 's/screen_color = (WHITE,DEFAULT,OFF)/screen_color = (WHITE,RED,OFF)/g' ~/.dialogrc
}

emph_colors()
{
sed -i -e 's/screen_color = (WHITE,DEFAULT,OFF)/screen_color = (WHITE,MAGENTA,OFF)/g' ~/.dialogrc
}

mugino_colors()
{
sed -i -e 's/screen_color = (WHITE,DEFAULT,OFF)/screen_color = (WHITE,GREEN,OFF)/g' ~/.dialogrc
}

menu_select_sjob()
{
running=1
vvxd=/tmp/menu.sh.$$
while [ $running -eq 1 ]
do
dialog  --colors --clear  --backtitle "$mastertitle" \
--colors --title "\Zb[ Multi File Job ]\Zn" \
--menu "Select Mode:" 14 40 8 \
2x "2x Scale" \
2x_nr "2x Scale + Noise Reduction" \
4x "4x Scale" \
4x_nr "4x Scale + Noise Reduction" \
nr "Noise Reduction Only" \
Back "Return to menu" 2>"${vvxd}"

menuitem=$(<"${vvxd}")


# make decsion
case $menuitem in
	2x) cssmode=0; Runtime_Core_Job_Single 2x 1 nop;;
	2x_nr) cssmode=1; Runtime_Core_Job_Single 2x 1 nop;;
	4x) Runtime_Core_Job_Single 4x 0 nop;;
	4x_nr) Runtime_Core_Job_Single 4x 0 nop;;
	nr) Runtime_Core_Job_Single nr 1 nop;;
	Back) running=0;;
esac

done
}

menu_select_bjob()
{
running=1
vvpd=/tmp/menu.sh.$$

while [ $running -eq 1 ]
do
dialog  --colors --clear  --backtitle "$mastertitle" \
--colors --title "\Zb[ Multi Folder Job ]\Zn" \
--menu "Select Mode:" 14 40 8 \
2x "2x Scale" \
2x_nr "2x Scale + Noise Reduction" \
4x "4x Scale" \
4x_nr "4x Scale + Noise Reduction" \
nr "Noise Reduction Only" \
Back "Return to menu" 2>"${vvpd}"

menuitem=$(<"${vvpd}")

# make decsion
case $menuitem in
	2x) cssmode=0; Runtime_Core_Job_Multi 2x 1 0;;
	2x_nr) cssmode=1; Runtime_Core_Job_Multi 2x 1 1;;
	4x) Runtime_Core_Job_Multi 4x;;
	4x_nr) Runtime_Core_Job_Multi 4x_nr;;
	nr) Runtime_Core_Job_Multi nr;;
	Back) running=0;;
esac

done
}

menu_enter_file()
{
echo "not setup"
}

menu_enter_url()
{

dialog  --colors --title "Web Retrival" \
--backtitle "$mastertitle" \
--inputbox "URL: " 8 75 2>$OUTPUT
 
respose=$?
name=$(<$OUTPUT)

case $respose in
  0)   	
	dialog  --colors --title "Web Retrival" \
	--yesno "Is this your file?\n$(wget ${name})" 10 40
	
  	;;
  1) 
  	echo "Cancel pressed." 
  	;;
  255) 
   echo "[ESC] key pressed."
esac

}

menu_disp_info()
{
echo "not setup"
}



#########################################################################################################

reset_colors

dialog  --colors --title " [ Bootup ] " --infobox "\n\
    _/      _/                      _/                            _/_/_/    _/_/_/    _/_/_/\n\
   _/_/  _/_/  _/    _/    _/_/_/      _/_/_/      _/_/        _/        _/        _/       \n\
  _/  _/  _/  _/    _/  _/    _/  _/  _/    _/  _/    _/      _/          _/_/      _/_/    \n\
 _/      _/  _/    _/  _/    _/  _/  _/    _/  _/    _/      _/              _/        _/   \n\
_/      _/    _/_/_/    _/_/_/  _/  _/    _/    _/_/          _/_/_/  _/_/_/    _/_/_/      \n\
                           _/                                                               \n\
                      _/_/                                                                  \n\n\
Mugino CUDA Super Scaler (Powered by: Waifu2x and Torch7)\n\
Wait for code to load..." 13 96

sleep 3

#### START HERE ####

vvvd=/tmp/menu.sh.$$

while true
do

### display main menu ###
dialog  --colors --clear  --backtitle "$mastertitle" \
--colors --title "\Zb[ MCSS Control Panel ]\Zn" \
--menu "\ZbSystem is now ready\Zn \n\
Processor Card: $gpuname \n\
Processor Card Cores: $gpucores \n\
Processor Card Temp: $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-) \n\
\n\
Select a command" 18 100 6 \
Multi_File "Runs a single job for master input folder" \
Multi_Folder "Runs multiple jobs for multiple folders" \
Single_File "Runs a single file" \
Single_URL "Runs a single file from the internet via URL" \
Info "Get Infomation on this Mugino System" \
Exit "Exit MCSS and return to console" \
Delete_Temp "Clears temp files (for external failure)" \
Delete_Data "DANGER, Deletes all outputed data" 2>"${vvvd}"
 
menuitem=$(<"${vvvd}")
 
 
# make decsion 
case $menuitem in
	Multi_File) menu_select_sjob;;
	Multi_Folder) menu_select_bjob;;
	Single_File) menu_enter_file;;
	Single_URL) menu_enter_url;;
	Info) menu_disp_info;;
	Exit) clear ; break;;
	Delete_Temp) DataMgr_Clean_Temp;;
	Delete_Data) DataMgr_Clean_All;;
	1) clear ; break;;
	255)  clear ; break;;
esac
 
done
[ -f $vvvd ] && rm $vvvd
