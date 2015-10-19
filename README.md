![My image](https://github.com/UiharuKazari2008/MuginoCSS/blob/master/img/MuginoCCS.jpg)
# MuginoCSS
Mugino CUDA Super Scaler is a batch image scaler that uses Waifu2x
CSS comes with EMPH, this allows you to 2x items from 20K(longest edge)!

## Prerequisites
1. Linux ( I am running Ubuntu 14.04.3 LTS)
2. NVidia GPU with CUDA (I have used a GTX 650 and GTX 760 Ti)
3. Define your CUDA bin directory in your PATH (Example: "/usr/local/cuda-7.0/bin/)
4. Install Waifu2x and confimed that it works (Here: https://github.com/nagadomi/waifu2x)
  1. Use (https://github.com/nagadomi/waifu2x/commit/b27ba28e1727454690d1ac12edbce8bb399015cc) as your install guide as he has not updated his guide and you will fail without this
5. Install uuid package
6. Install ImageMagick package
7. Install 

## Install
1. Pull this down somewhere
2. move the contents to /opt/mugino-css/
3. Move or Install all of Waifu2x into /opt/mugino-css/lib (NOT ../lib/waifu2x)
  1. If you dont want to move it there, you need to update the line that CD's into it. and make sure you have can access it
4. Make sure YOU have RWX to everything in /opt/mugino-css/
5. Move the the .desktop file to /usr/share/applications for one-click launch (MultiJob shortcut is on its way)
6. Update the exports in the top to select where you want your data to stored and pulled from

## Usage
### One Job
1. Put images into <Master Input>/2x
2. Run Mugino CSS with shortcut or "bash /opt/mugino-css/mcss-run"
3. Select Single Job
4. Select mode.
5. Wait
6. Output will be in <Master Output>
7. Profit 

### Multi Job
1. Put folders of images into <Batch Folder>
2. Run "bash /opt/mugino-css/mcss-run
3. Select Multi Job
4. Select mode.
5. Wait
6. Output will be in /opt/mugino-css/output/2x/<Orig. Folder Name>
  1. Any files that are left in ../output are moved to ../output/unfiled

## To Do
1. Make the install scripted
4. Keep orginal file names
5. Fault recovery
6. Use Waifu2x Image list option
7. Add 4x Mode
8. Add Noise Reduction Only Optition
8. Add other operation modes
9. Add System Info Section
10. More stuff
