#!/bin/bash

#
# Mugino CUDA Super Scaler for *nix
#

 echo "Wait for code to load..."

#########################################################################################################
################################### init vars ###################################

# Define Main Back Title and GPU Name
mastertitle="Mugino CUDA Super Scaler v1.72"
gpuname="$(nvidia-smi -q | grep "Product Name " | cut -c 39-)"
gpucores="$(/cuda/NVIDIA_CUDA-7.0_Samples/1_Utilities/deviceQuery/deviceQuery | grep "CUDA Cores")"

# Define Locations
export dir_master_in="/photodata/Import"
export dir_master_out="/photodata/Output"
export dir_emph_in="/photodata/tmp/m-emph/input"
export dir_emph_out="/photodata/tmp/emph/ouput"
export dir_emph_blocks="/photodata/tmp/emph/blks"
export dir_emph_blocks_done="/photodata/tmp/emph/blocks-comp"
export dir_emph_ocd="/photodata/tmp/emph/oc-data"
export dir_std_in="/photodata/tmp/std/in"
export dir_std_out="/photodata/tmp/std/out"
export dir_css_in="/photodata/tmp/css"
export dir_css_out="/photodata/tmp/css-out"
export dir_ccs_log="/photodata"
export dir_ccs_lib="/opt/mugino-css/lib"
export dir_master_batch_in="/photodata/Batch"

# Check if Locations exixt, if not make them
[ -d ${dir_master_out}/unfiled ] || mkdir -p ${dir_master_out}/unfiled
[ -d ${dir_master_in}/2x ] || mkdir -p ${dir_master_in}/2x/
[ -d ${dir_master_batch_in}/2x ] || mkdir -p ${dir_master_batch_in}/2x/
[ -d ${dir_emph_in}/2x ] || mkdir -p ${dir_emph_in}/2x/
[ -d ${dir_emph_out}/2x ] || mkdir -p ${dir_emph_out}/2x/
[ -d ${dir_emph_blocks}/2x ] || mkdir -p ${dir_emph_blocks}/2x/
[ -d ${dir_emph_blocks_done}/2x ] || mkdir -p ${dir_emph_blocks_done}/2x/
[ -d ${dir_std_in}/2x ] || mkdir -p ${dir_std_in}/2x/
[ -d ${dir_std_out}/2x ] || mkdir -p ${dir_std_out}/2x/
[ -d ${dir_css_in}/2x ] || mkdir -p ${dir_css_in}/2x/
[ -d ${dir_css_out}/2x ] || mkdir -p ${dir_css_out}/2x/
[ -d ${dir_css_lib} ] || echo "CCS Lib was not found, can not run without it"

################################### Runtime ###################################

## Single Job Interface, Sort, Check, Run, Check, Run, Move (4x itter 1 skip)
# Input(s): Mode (2x, 4x, 6x, 8x); Finish (Move to M.Complete? 1 or 0); Project Name (No Project name = "nop")
# Outputs (s):
run_sjob()
{
# Is there files in the input?
totalitems="$(ls ${dir_master_in}/${1}/  | wc -l)"
if [ ${totalitems} != 0 ]; then
	# Make MCSS files
	run_rename ${1}
	# Sort Files
	run_sortl1 ${1}
	# Init Error count
	errorcount=1
	# Init Item Count
	currentitem=1
	# Is there EMPH tasks?
	if [ $(ls ${dir_emph_in}/${1}/ | wc -l) != 0 ]; then
		# Run EMPH Runtime
		run_task_emph ${1} "${3}" ${totalitems}
	# There is no files, tick coutner
	else
		errorcount=$((++errorcount))
	fi
	# Is there Standard tasks?
	if [ $(ls ${dir_std_in}/${1}/ | wc -l) != 0 ]; then
		# Run STD Runtime
		run_task_std ${1} "${3}" ${totalitems}
	# There are no files, tick counter
	else
		errorcount=$((++errorcount))
	fi
	# If both tasks fail then complain that there are no files to proccess, maybe the sorted content failed to be accessed?
	if [ ${errorcount} = 3 ]; then
		error_colors
		dialog --colors --title "\Zb[ ERROR in Data Manager ]\Zn" --infobox "No Data was found in any of runtime inputs\n\
This could mean that:\n\
1. You did not define the dir_<runtime>_in or out var \n\
2. The defined values are not readable or denied access\n\
Please correct this issue and restart MCSS \n\n\
Runtime - Standard: ${dir_std_in} \n\
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
	dialog --colors --title "\Zb[ ERROR: Need Input ]\Zn" --infobox "No Data is in folder for the job\n\
Please put your data in the folder and run again.\n\n\
Folder: ${dir_master_in}" 6 53
	reset_colors
	sleep 2
fi
}

run_bjob()
{
# Clean up output and temp
run_move_unfiled
run_clean_temp
# Change contex to master batch dir
cd "${dir_master_batch_in}/${1}"
totalprojects="$(ls ${dir_master_batch_in}/${1}/  | wc -l)"
currentproject=1
dialog --colors --title "\Zb[ Mugino Data Inspector ]\Zn" --infobox "Preparing Projects...\n\
\ZbProjects:\Zn ${totalprojects}" 4 46
sleep 2
if [ $(ls ${dir_master_batch_in}/${1}/  | wc -l) != 0 ]; then
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
  run_sjob ${1} 0 "${d}"
  currentproject="$((currentproject + 1))"
  mkdir "${dir_master_out}/$d"
  mv ${dir_emph_out}/${1}/*.png "${dir_master_out}/$d"
  mv ${dir_std_out}/${1}/*.png "${dir_master_out}/$d"
  cd "${dir_master_batch_in}/${1}"
  fi
  }
done
else
dialog --colors --title " [ DATA ERROR ] " --infobox "No Data is in folder for the job\n\
Please put your data in the folder and run again.\n\
Folder: ${dir_master_in}" 5 53
sleep 2
fi
}

## Run Standrard Runtime
# Input(s): 
# Outputs (s): 
run_task_std() 
{
dialog --title "Data Manager" --infobox "Preparing Data..." 3 30
cd ${dir_std_in}/${1}
# get number of files
n=$(ls * | wc -l)
# Progress Display that has the runtime object in it
dialog --backtitle "$mastertitle" --title " [ Mugino Meltdowner ] " --gauge "Waiting for init pipeline... \n\
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
echo "File: $file ( ${currentitem}/${3} )"
echo " "
echo " ---- File Info ----"
echo "Current: "$(identify -format "%w x %h (%m " ${dir_std_in}/${1}/${file})$(du -sh ${dir_std_in}/${1}/${file} | cut -c -4 | sed -e 's/^[ \t]*//')") -> MCSS Runtime"
echo "Last: "$(makedisp ${prev} ${1} ${dir_std_in} ${dir_std_out})
echo " -------------------"
echo " "
echo "Processor Card: $gpuname @ $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)"
echo "XXX"
echo "$pres"
#do the task
run_css ${1} ${dir_std_in} ${dir_std_out} ${file}
# Update XX#% var
{
if [ i = 0 ]
then
pres=$(( 100*(1)/n ))
else
pres=$(( 100*(++i)/n ))
fi
}
prev=$file
currentitem=$(( currentitem + 1 ))
done
dialog --clear
)
}

## Run EMPH Runtime
# Input(s): Mode (Piped String)
# Outputs (s): File data-output (PNG File, No contex)
run_task_emph() 
{
# Change contex
cd ${dir_emph_in}/${1}
# For each file, run EM, then run CSS, then run PH, then move to output
for file1 in *.*;
do
{
# Move file to out of contex input file
mv ${dir_emph_in}/${1}/${file1} ${dir_emph_ocd}
# Define Crop Grid, Call function and use output as var
emph_crop=$(is_crop ${dir_emph_ocd})
# Run EMo
dialog --title " [ EMPH Task Control (Task 1/3) ] " --infobox "Processing Data @ ${emph_crop}..." 3 46
run_emo ${emph_crop} ${1}
# Change contex
cd ${dir_emph_blocks}/${1}
# For each block, run CCS
n=$(ls emo_block* | wc -l)
# Progress Display that has the runtime object in it
dialog --backtitle "$mastertitle" --title " [ Mugino Meltdowner (from EMPH Task) ] " --gauge "Waiting for init pipeline... \n\
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
echo "Parent File: $file1 ( ${currentitem}/${3} )"
echo "Block: $filexx from ${emph_crop} file grid"
echo " "
echo " ---- File Info ----"
echo "Current: "$(identify -format "%w x %h (%m " ${dir_emph_blocks}/${1}/${filexx})$(du -sh ${dir_emph_blocks}/${1}/${filexx} | cut -c -4 | sed -e 's/^[ \t]*//')") -> MCSS Runtime"
echo "Last: "$(makedisp $prev ${1} ${dir_emph_blocks} ${dir_emph_blocks_done})
echo " -------------------"
echo " "
echo "Processor Card: $gpuname @ $( nvidia-smi -q | grep "GPU Current Temp" | cut -c 39-)"
echo "XXX"
echo "$pres"
#do the task
run_css ${1} ${dir_emph_blocks} ${dir_emph_blocks_done} ${filexx}
# Update XX#% var
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
dialog --title " [ EMPH Task Control (Task 3/3) ] " --infobox "Processing Data..." 3 46
run_phoenix $emph_crop ${1} $file1
dialog --title " [ EMPH Task Control (Task 3/3) ] " --infobox "Processing Data... COMPLETE!" 3 46
sleep 2
}
currentitem=$(( currentitem + 1 ))
done
}

################################### Data Manager ###################################

## Rename Items to UUID (for file name problems)
# Input(s): Mode
# Outputs (s): 
run_rename() 
{
dialog --title " [ Mugino Data Control ] " --infobox "Preparing Input..." 3 46
cd ${dir_master_in}/${1}/
for files in *
do
  mv "$files" ./$(uuid).mcss;
done
dialog --title " [ Mugino Data Control ] " --infobox "Preparing Input... DONE" 3 46
sleep 1
}

## Input Data Sort, find data that needs EMPH, if true sort it for it
# Input(s):
# Outputs (s): 
run_sortl1() 
{
cd ${dir_master_in}/${1}/
dialog --title " [ Mugino Data Inspector ] " --infobox "Preparing Data...\n\
Items: $(ls ${dir_master_in}/${1}/*.mcss | wc -l)" 4 46
enumm=1
for file in *.mcss;
do
{
#Get HxW
hx=$(identify -format "%h" ${dir_master_in}/${1}/${file})
wx=$(identify -format "%w" ${dir_master_in}/${1}/${file})
#
#Find longest edge
if [ $hx -ge $wx ]
then
hig=$hx
else
hig=$wx
fi
# If file is over 3000px (longest edge) then move it to EMPH input
if [ $hig -ge 3000 ]
then
	#Move to be procced by EMPH
	mv ${dir_master_in}/${1}/${file} ${dir_emph_in}/${1}
fi
}
done
# Move everything else (under 3000px) to input that will be done later
for file in *.mcss;
do
mv ${dir_master_in}/${1}/${file} ${dir_std_in}/${1} &> /dev/null
done
dialog --title " [ Mugino Data Inspector ] " --infobox "Preparing Data...\n\
Items: $(ls ${dir_std_in}/${1}/*.mcss | wc -l) ( $(ls ${dir_emph_in}/${1}/*.mcss | wc -l) will use EMPH )" 4 46
sleep 1
}

## Clean up temp directorys
# Input(s): None
# Outputs (s): None
run_clean_temp() 
{
dialog --title " [ Data Manager ] " --infobox "Cleaning up..." 3 30
rm ${dir_emph_in}/* &> /dev/null
rm ${dir_emph_out}/* &> /dev/null
rm ${dir_emph_blocks}/* &> /dev/null
rm ${dir_emph_blocks_done}/* &> /dev/null
rm ${dir_emph_ocd} &> /dev/null
rm ${dir_std_in}/* &> /dev/null
rm ${dir_std_out}/* &> /dev/null
rm ${dir_css_in}/* &> /dev/null
rm ${dir_css_out}/* &> /dev/null
dialog --title " [ Data Manager ] " --infobox "Files are removed" 3 30
sleep 1
}

run_move_unfiled()
{
dialog --title " [ Data Manager ] " --infobox "Moving unfiled images..." 3 30
if [ $(ls ${dir_master_out}/*.png | wc -l) != 0 ]; then
    mv ${dir_master_out}/*.png ${dir_master_out}/unfiled
    dialog --title " [ Data Manager ] " --infobox "Moved to /unfiled" 3 30
else
dialog --title " [ Data Manager ] " --infobox "Nothing to move" 3 30
fi
sleep 1
}

################################### Infomation ###################################

## EMPH Grid calculator
# Input(s): File (Piped String (UUID.mcss))
# Outputs (s): Piped String "Grid Size (#x#)"
is_crop() {
#Get File Info
hx=$(identify -format "%h" ${1})
wx=$(identify -format "%w" ${1})
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
makedisp()
{
if [ ${1} != "nopipe" ]
then
echo $(identify -format "%w x %h (%m " ${3}/${2}/${1})$(du -sh ${3}/${2}/${1} | cut -c -4 | sed -e 's/^[ \t]*//')") -> "$(identify -format "%w x %h (%m " ${4}/${2}/${1}.png)$(du -sh ${4}/${2}/${1}.png | cut -c -4 | sed -e 's/^[ \t]*//')")"
# in "$(tail -1 /opt/mugino-css/css_log.log | sed -e 's/^[ \t]*//')
fi
if [ ${1} = "nopipe" ]
then
echo " "
fi
}


################################### MCSS ###################################

## MCSS Runtime (Scale Mode)
# Input(s): File (Piped String (MCSS ? Image, Out of contex), Mode (Piped String)
# Outputs (s): File (Piped String (MCSS PNG Image, No contex)
run_css() 
{
# Go to library
if [ ${cssmode} = 1 ]; then
	prossmode="noise_scale -noise_level 1"
fi
if [ ${cssmode} = 0 ]; then
	prossmode="scale"
fi
cd  /opt/mugino-css/lib/
# Run Scaler with input from the current mode
th waifu2x.lua -m ${prossmode} -i  ${2}/${1}/${4} -o  ${3}/${1}/${4}.png &>> $dir_ccs_log/css_log.log
}


################################### EMPH ###################################

## EMo: Cuts file up into grid to account for low resources
## Get the pun.....emo....cut.....
# Input(s): Crop (Piped String (#x#)), ${dir_master_out}/emph/data-input (PNG File, Out of contex)
# Outputs (s): File data-output (PNG File, No contex)
run_emo() 
{
cd ${dir_emph_blocks}/${2}
# Cut file by given grid
convert ${dir_emph_ocd} -crop ${1}@ +repage +adjoin "emo_block_%d"
# Remove input file
rm ${dir_emph_ocd}
}

## PHoenix: Recompiles the grid for final output
## Get the pun.....phoenix....recontructs.....
# Input(s): None
# Outputs (s): ${dir_master_out}/emph/data-output (PNG File, No contex)
run_phoenix() 
{
cd ${dir_emph_blocks_done}/${2}
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
montage -mode concatenate -tile ${1} emo_block_* ${dir_emph_ocd}
mv ${dir_emph_ocd} ${dir_emph_out}/${2}/${3}.png
# Remove old blocks from EMo
rm emo_block_*
cd ${dir_emph_blocks}/${2}
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
sed -i -e 's/screen_color = (WHITE,MAGENTA,OFF)/screen_color = (WHITE,DEFAULT,OFF)/g' ~/.dialogrc
}

mugino_colors()
{
sed -i -e 's/screen_color = (WHITE,GREEN,OFF)/screen_color = (WHITE,DEFAULT,OFF)/g' ~/.dialogrc
}

menu_select_sjob()
{
running=1
vvxd=/tmp/menu.sh.$$
while [ $running -eq 1 ]
do
dialog --clear  --backtitle "$mastertitle" \
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
	2x) cssmode=0; run_sjob 2x 1 nop;;
	2x_nr) cssmode=1; run_sjob 2x 1 nop;;
	4x) run_sjob 4x 0 nop;;
	4x_nr) run_sjob 4x 0 nop;;
	nr) run_sjob nr 1 nop;;
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
dialog --clear  --backtitle "$mastertitle" \
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
	2x) cssmode=0; run_bjob 2x 1 0;;
	2x_nr) cssmode=1; run_bjob 2x 1 1;;
	4x) run_bjob 4x;;
	4x_nr) run_bjob 4x_nr;;
	nr) run_bjob nr;;
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

dialog --title "Web Retrival" \
--backtitle "$mastertitle" \
--inputbox "URL: " 8 75 2>$OUTPUT
 
respose=$?
name=$(<$OUTPUT)

case $respose in
  0)   	
	dialog --title "Web Retrival" \
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

sleep 2

#### START HERE ####

vvvd=/tmp/menu.sh.$$

while true
do

### display main menu ###
dialog --clear  --backtitle "$mastertitle" \
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
	Delete_Temp) run_clean_temp;;
	Delete_Data) run_clean_all;;
	1) clear ; break;;
	255)  clear ; break;;
esac
 
done
[ -f $vvvd ] && rm $vvvd
