# Amplitube5-Uninstaller
![uninstaller](https://raw.githubusercontent.com/thinker99k/AmpliTube5-Uninstaller/refs/heads/main/img/uninstaller.png)

## How to use
1. **Unauthorize AmpliTube 5 in IK Product Manager**
2. Download *script.zsh*
3. Open terminal and do
   1. `xattr -d com.apple.quarantine SCRIPT_PATH` : disable quarantine flag on script
   2. `chmod +x SCRIPT_PATH` : grant execute privilege to script
   3. `sudo SCRIPT_PATH` : actual run of script
   
   ![howtouse](https://raw.githubusercontent.com/thinker99k/AmpliTube5-Uninstaller/refs/heads/main/img/howtouse.png)

   (To fill `FILE_LOCATION`, just drag *script.zsh* from finder to terminal)

## DISCLAIMER
**USE AT YOUR OWN RISK**

Author(s) of this repo do(es) not have charge on any malfunctions, so backup important files before run this script

Tested on
- MacOS Seqouia 15.7.7
- Mac Mini (2018)
- AmpliTube 5 MAX v2, 5.10.9

---
Any PR will be appreciated!