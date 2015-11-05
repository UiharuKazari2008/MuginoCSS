![My image](https://github.com/UiharuKazari2008/MuginoCSS/blob/master/img/MuginoCCS.jpg)
# MuginoCSS
Mugino CSS is a batch/project image scaler that uses Waifu2x, MCSS comes with EMPH which breaks up very large images into small chunks that are scaled and then recomplied, this allows you to 2x items from 20K(longest edge) to 40K!!

## Prerequisites
1. Supported Linux Distro ( I am running Ubuntu Server 14.04.3 LTS) (Tested to work with both Desktop and Server)
2. NVidia GPU with CUDA Installed (I have used a GTX 650 and GTX 780 Ti) (Tested to work with both CUDA 7.0 and CUDA 7.5)
  1. Install CUDA with samples, and make the first utility called deviceq.. (cant spell right now)
3. Define your CUDA bin directory in your PATH (Example: /usr/local/cuda-7.5/bin/)
4. Install Waifu2x and confimed that it works (Here: https://github.com/nagadomi/waifu2x)
  1. Use (https://github.com/nagadomi/waifu2x/commit/b27ba28e1727454690d1ac12edbce8bb399015cc) as your install guide as he has not updated his guide and you will fail without this
5. apt-get insall imagemagick

### Optional
6. apt-get install stepic (ONLY if you will be using -k option, ITS NOT A REQUIREMENT. But its pretty cool!)

## Install
1. Pull this down somewhere
2. move the contents to /opt/mugino-css/ (Its possible to not use this but you need update the setting in mugino.bash)
3. Move or Install all of Waifu2x into /opt/mugino-css/waifu2x (same as above just update the settings)
4. Make sure YOU have RWX to everything in /opt/mugino-css/
5. EDIT THE SETTINGS AT THE TOP OF MUGINO.BASH
6. Run your first job

## Usage
```
MUGINO -x <S> -m <S> [-n] [-i <S>] [-o <S>] [-k or -K] [-O <#>] [-c]

	-x Exec Mode (String)
		run - Runs a new job
		prep - Generates the job file only (For running later or transport)
		p-run - Runs the prepared job file, must be in CSS directory
		inject - Inject a project(s) into the current job (will run after current ITEM)
		append - Append a project(s) after the current job (will run after current JOB)
		recover - Recover orginal image from output image, MUST HAVE USED KIFR!

	-m Scaler Mode (String)
		2 - 2x Scale Mode
		4 - 4x Scale Mode
		0 - No scaling, for NR only mode

	-n Noise Reduction

	-i/-o Input/Output
		Overrides the default dirs
		DO NOT PUT A '/' ON THE END 

	-k KIFR (Keep Input for Recovery)
		This uses steganography to place the original file in the output for recovery
		Uses the Input image file as a payload
		This was added for as a P.O.C. for a class at university

		WARNING!!
		 1. DO NOT re-save the image with any editor, the embedded image WILL be LOST
		 2. This WILL increase the output file size
		 3. This will take some CPU power to pull off and will extend the time
		 4. This does not play well with transparent images, transparently will become black
		    in areas that it has written to. So some images will be half transparent half black bg

	-O Omit (Number), Omit any file that is larger then X

	-c Move input items
		When dealing with a non-static input, this will copy the input for safty

	-y Will skip confirm and run
```

### Examples

Run 2x with default I/O
```
mugino.bash -x run
```
Run 2x + Noise Reduction with default I/O
```
mugino.bash -x run -n
```
Lets get advanced, Inject 2x + Noise Reduction with custom I/O, Use KIFR, Only images under 2048px, 
```
mugino.bash -x inject -m 2 -n -i '/home/mugino/customfiles' -o '/media/usb0/TurboTax/2008/Not Porn' -k -O 2048 
```
Recover orginal from outputed file from custom input folder
```
mugino.bash -x recover -i '/home/mugino/files to recover'
```
Have fun!

## Changes

###10/20/2015
1. No more UUID file names, now it supports orginal file names. Even with bad things liek spaces and stuff like that.
2. Updated to reflect CUDA 7.5 (I rebuilt my sever so i am now on the latest)

###10/25/2015
1. Major changes, no more GUI. You can tail the log file. There will be a GUI to interface with it soon
2. A little better with error recovery, runs off job files but i need to make it see that a job file exsists so it can finish it
3. 4x mode works! Kindof, it has no EMPH support so it can fail on 2nd pass
4. Now supports max input size

###10/29/2015
1. Uses getopts for options
2. Injects Works! and also has Append mode too.
3. Will confirm before it runs the task, use -y to skip
4. Uses stepic to embedded orginal image into output for recovery later, read the warnings! this is the -k option

###11/05/2015
1. MCSS-RUN.SH is removed and is now split up between Mugino.bash and mugino-worker.bash. This allows the usage of nohup so task can run even after a TTY hangup.
2. Task is now backgrounded
3. Only interface with mugino.bash, there is a sanity check in the worker to stop you from running it outside of mugino.
  
## To Do
1. Make the install scripted
8. Add other operation modes
10. More stuff
11. Beta Testers and contribs wanted!
12. Config file
13. Unattended Batch Mode