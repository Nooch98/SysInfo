# SysInfo
SysInfo is a Powershell script that provides information about software, hardware, security and additional information similar to neofetch but created with Windows in mind since neofetch has been discontinued

![Captura de pantalla 2024-05-30 181610](https://github.com/Nooch98/SysInfo/assets/73700510/2cd6651a-83fe-4e34-bfd3-824cf4fc7f9e)

# UPDATES
## 13/08/2024
* I have added when starting the script the option to activate a developer mode so that if it is being modified and tested it does not run the search for updates and shows messages about what the script is doing
* I have changed how updates are checked
* Now the script will ask you if you want to update it (except if you are in development mode which will never be updated)
* Add to also show the GPU usage

## 30/05/2024
* I corrected how the information about the dedicated memory of the graphics card is obtained and now it is displayed correctly
* Change how you get the version of the graphics drivers if it is Nvidia
* Processor speed was also added as information
* Added an autoupdate for the script [!] If you do not have the script saved in the path C:\Users\USER\Documents\PowerShell\Scripts you only need to change these two lines in the code for it to work correctly

![Captura de pantalla 2024-05-30 200836](https://github.com/Nooch98/SysInfo/assets/73700510/243f0ccc-8067-4955-b676-359028388c88)

## 22/05/2024
* small parts of the code have been changed to avoid repetition and optimize performance, it is now much faster
* A new piece of information has been added which are the Date of the Last Security Update
