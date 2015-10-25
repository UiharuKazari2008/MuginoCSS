![My image](https://github.com/UiharuKazari2008/MuginoCSS/blob/master/img/MuginoCCS.jpg)
# MuginoCSS
Mugino CUDA Super Scaler is a batch/project image scaler that uses Waifu2x, MCSS comes with EMPH which breaks up very large images into small chunks that are scaled and then recomplied, this allows you to 2x items from 20K(longest edge) to 40K!!

## Prerequisites
1. Linux ( I am running Ubuntu Server 14.04.3 LTS) (Tested to work with both Desktop and Server)
2. NVidia GPU with CUDA (I have used a GTX 650 and GTX 760 Ti) (Tested to work with both CUDA 7.0 and CUDA 7.5)
  1. Install CUDA with samples, and make the first utility called deviceq.. (cant spell right now)
3. Define your CUDA bin directory in your PATH (Example: "/usr/local/cuda-7.5/bin/)
4. Install Waifu2x and confimed that it works (Here: https://github.com/nagadomi/waifu2x)
  1. Use (https://github.com/nagadomi/waifu2x/commit/b27ba28e1727454690d1ac12edbce8bb399015cc) as your install guide as he has not updated his guide and you will fail without this
5. Install ImageMagick package

## Install
1. Pull this down somewhere
2. move the contents to /opt/mugino-css/
3. Move or Install all of Waifu2x into /opt/mugino-css/waifu2x
  1. If you dont want to move it there, you need to update the line that CD's into it. and make sure you have can access it
4. Make sure YOU have RWX to everything in /opt/mugino-css/
5. Move the the .desktop file to /usr/share/applications for one-click launch (MultiJob shortcut is on its way)
6. Update the directory exports in the top to select where you want your data to stored and pulled from
  1. Set the directory where MCSS is, default is /opt/mugino-css/ you can change it and move it before or after install
  2. Set where injects will be read from
  3. Tmp is where files are exchanged and placed during scaleing (In my cause I have a highspeed USB 3.0 drive used) (REQUIRED TO BE CHANGED!!!!)
  4. Change what is the max size a image can be before EMPH is triggered, a.k.a. how large before it hits your systems RAM limit

## Usage
Run it with no input to see usage or read below
### Normal
1. Put images/folders into a folder
2. Run "bash /opt/mugino-css/mcss-run.sh /dir/input /dir/output 2"
  1. Input directory
  2. Output Directory
  3. Mode (2 = 2x, 4 = 4x, 2nr = 2x with Noise Reduction, etc.)
  4. Optional: Input must be smaller then X (Example: 3000 = no image over 3000px will be accepted)
3. Tail the log at /opt/mugino-css/mcss.log
4. Output will be in specifed output folder
5. Profit 

### Injects (WIP, does not work ATM)
Injects allow you to "inject" a file or folder into the current job and give it ASAP priority
1. Put images/folders into inject folder
2. Wait till current item is done, then injects will be ran
3. Tail the log at /opt/mugino-css/mcss.log
4. Output will be in specifed output folder
5. Profit 

## Changes
###10/20/2015
No more UUID file names, now it supports orginal file names. Even with bad things liek spaces and stuff like that.
Updated to reflect CUDA 7.5 (I rebuilt my sever so i am now on the latest)
###10/25/2015
Major changes, no more GUI. You can tail the log file. There will be a GUI to interface with it soon
A little better with error recovery, runs off job files but i need to make it see that a job file exsists so it can finish it
4x mode works! Kindof, it has no EMPH support so it can fail on 2nd pass
Now supports max input size

  
## To Do
1. Make the install scripted
5. Fault recovery!!
6. Use Waifu2x Image list option
8. Add Noise Reduction Only Optition
8. Add other operation modes
10. More stuff
11. Beta Testers and contribs wanted!
12. Config file
13. Unattended Batch Mode
14. Logging