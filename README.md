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
6. Install ImageMagick package
7. Install dialog package

## Install
1. Pull this down somewhere
2. move the contents to /opt/mugino-css/
3. Move or Install all of Waifu2x into /opt/mugino-css/waifu2x
  1. If you dont want to move it there, you need to update the line that CD's into it. and make sure you have can access it
4. Make sure YOU have RWX to everything in /opt/mugino-css/
5. Move the the .desktop file to /usr/share/applications for one-click launch (MultiJob shortcut is on its way)
6. Update the directory exports in the top to select where you want your data to stored and pulled from
  1. Master Input and Master Output is where you put your files that you want scaled
  2. Batch is where you put your project folders to be bulk scaled
  3. Tmp is where files are exchanged and placed during scaleing (In my cause I have a highspeed USB 3.0 drive used)

## Usage
### One Job
1. Put images into <Master Input>/2x
2. Run Mugino CSS with shortcut or "bash /opt/mugino-css/mcss-run.sh"
3. Select Single Job
4. Select mode.
5. Wait
6. Output will be in <Master Output>
7. Profit 

### Multi Job
1. Put folders of images into <Batch Folder>
2. Run "bash /opt/mugino-css/mcss-run.sh
3. Select Multi Job
4. Select mode.
5. Wait
6. Output will be in <Master Output>/<Orig. Folder Name>
  1. Any files that are left in <Master Output> are moved to <Master Output>/unfiled

## Changes
###10/20/2015
No more UUID file names, now it supports orginal file names. Even with bad things liek spaces and stuff like that.
Updated to reflect CUDA 7.5 (I rebuilt my sever so i am now on the latest)

  
## To Do
1. Make the install scripted
5. Fault recovery!!
6. Use Waifu2x Image list option
7. Add 4x Mode
8. Add Noise Reduction Only Optition
8. Add other operation modes
9. Add System Info Section
10. More stuff
11. Beta Testers and contribs wanted!
12. Config file
13. Unattended Batch Mode
14. Logging
15. Input/Output Recovery in the event of failure