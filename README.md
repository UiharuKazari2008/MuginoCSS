![My image](https://github.com/UiharuKazari2008/MuginoCSS/blob/master/img/MuginoCCS.jpg)
# MuginoCSS
Mugino CSS is a batch/project image scaler that uses Waifu2x, MCSS comes with EMPH which breaks up very large images into small chunks that are scaled and then recomplied, this allows you to 2x items from 20K(longest edge) to 40K!!

## Prerequisites
1. Linux ( I am running Ubuntu Server 14.04.3 LTS) (Tested to work with both Desktop and Server)
2. NVidia GPU with CUDA (I have used a GTX 650 and GTX 760 Ti) (Tested to work with both CUDA 7.0 and CUDA 7.5)
  1. Install CUDA with samples, and make the first utility called deviceq.. (cant spell right now)
3. Define your CUDA bin directory in your PATH (Example: "/usr/local/cuda-7.5/bin/)
4. Install Waifu2x and confimed that it works (Here: https://github.com/nagadomi/waifu2x)
  1. Use (https://github.com/nagadomi/waifu2x/commit/b27ba28e1727454690d1ac12edbce8bb399015cc) as your install guide as he has not updated his guide and you will fail without this
5. apt-get insall imagemagick
6. apt-get install stepic (ONLY if you will be using -k option, ITS NOT A REQUIREMENT. But its pretty cool!)

## Install
1. Pull this down somewhere
2. move the contents to /opt/mugino-css/
3. Move or Install all of Waifu2x into /opt/mugino-css/waifu2x
  1. If you dont want to move it there, you need to update the line that CD's into it. and make sure you have can access it
4. Make sure YOU have RWX to everything in /opt/mugino-css/
5. Update the directory exports in the top to select where you want your data to stored and pulled from
  1. Set the directory where MCSS is, default is /opt/mugino-css/ you can change it and move it before or after install
  2. Set default dir's will be for injects, input, and output
  3. Tmp is where files are exchanged and placed during EMPH and for -c option (In my cause I have a highspeed USB 3.0 drive used) (REQUIRED TO BE CHANGED!!!!)
  4. Change what is the max size a image can be before EMPH is triggered, a.k.a. how large before it hits your systems RAM limit

## Usage
Run it with no options or -h option to see how to set the options

Run 2x with default I/O
```
mcss-run.sh -x run
```
Run 2x + Noise Reduction with default I/O
```
mcss-run.sh -x run -n
```
Lets get advanced, Inject 2x + Noise Reduction with custom I/O, Use KIFR, Only images under 2048px, 
```
mcss-run.sh -x inject -m 2 -n -i '/home/mugino/customfiles' -o '/media/usb0/TurboTax/2008/Not Porn' -k -O 2048 
```
Recover orginal from outputed file from custom input folder
```
mcss-run.sh -x recover -i '/home/mugino/files to recover'
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
  
## To Do
1. Make the install scripted
8. Add other operation modes
10. More stuff
11. Beta Testers and contribs wanted!
12. Config file
13. Unattended Batch Mode