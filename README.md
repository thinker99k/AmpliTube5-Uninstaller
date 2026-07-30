# AmpliTube5-Uninstaller

![uninstaller](https://raw.githubusercontent.com/thinker99k/AmpliTube5-Uninstaller/refs/heads/main/img/uninstaller.png)

## How to use

1. **Unauthorize AmpliTube 5 in IK Product Manager**
2. Download latest release version of *script.zsh*
   from [Releases](https://github.com/thinker99k/AmpliTube5-Uninstaller/releases)
3. Open terminal and do
   1. `xattr -d com.apple.quarantine SCRIPT_PATH` : disable quarantine flag on script
   2. `chmod +x SCRIPT_PATH` : grant execute privilege to script
   3. `sudo SCRIPT_PATH` : actual run of script

![howtouse](https://raw.githubusercontent.com/thinker99k/AmpliTube5-Uninstaller/refs/heads/main/img/howtouse.png)

(To fill `SCRIPT_PATH`, just drag *script.zsh* from finder to terminal)

## Why it needs?

IK provide official uninstaller of course, but it DEFINITELY SUCKS\
(You can find in `~/Documents/IK Multimedia/IK Product Manager/AmpliTube 5/AmpliTube_X_Y_Z.dmg`)

<details>
<summary>...let's see some of</summary>

- :22,25
  ```
  rm -Rf /var/db/receipts/com.ikmultimedia.pkg.HammondB-3X.bom
  rm -Rf /var/db/receipts/com.ikmultimedia.pkg.HammondB-3X.plist 
  
  sudo pkgutil --forget com.ikmultimedia.HammondB-3X
  ```
  [HammondB-3X](https://www.ikmultimedia.com/products/hammondb3x/) is virtual organ from IK, why this in 'AmpliTube 5'
  uninstaller??\
  It seems someone just copy and paste from somewhere

- :43
  ```
  #rm -f \"/Library/Preferences/com.ikmultimedia.AmpliTube 5.plist\"
  ```
  `pkgutil --forget` works same as delete .bom & .plist (read `man pkgutil`), `rm -f` is not a safe way to forget package\
  What's even worse; this line is annotated so **there's no forget of package** in whole script

- :52, :57, :62
  ```
  rm -Rf /Library/Application\\ Support/IK\\ Multimedia/AmpliTube\\ 5/
  
  sudo rm -Rf ~/Documents/IK\\ Multimedia/AmpliTube\\ 5/
  
  rm -Rf /Library/Documentation/IK\\ Multimedia/AmpliTube\\ 5/
  ```
  It never touches ~/Library, will leave **a bunch of garbages**

</details>

IK Product Manager checks whether program is installed or not by just\
`/Library/Application Support/IK Multimedia/<program_name>/` exists, wtf?

This script set 3 targets, delete in order of these guarantee clean removal like Jazz Chorus

<details>
<summary>TARGET </summary>

- **TARGET0** : .app itself
  - /Applications
- **TARGET1** : where package installer touches
  - pkgutil receipt(.plist, .bom)
  - /Library
  - /Applications (Duplicated with TARGET0)
- **TARGET2** : libraries
  - /Library (Duplicated with TARGET1)
  - ~/Library
- **TARGET3** : user files (preset, project, etc)
  - ~/Documents

</details>


## DISCLAIMER

**USE AT YOUR OWN RISK**

Author(s) of this repo do(es) not have charge on any malfunctions, so backup important files before run this script

Tested on

- macOS Seqouia 15.7.7
- Mac Mini (2018)
- AmpliTube 5 MAX v2, 5.10.9

---

## How to contribute

These kind of PRs will NOT be accepted

- **Break Readability** (ex. substituting duplicated snippet to separate function)\
  Shell script is always readability first
- **Require any network things** (ex. curl)\
  This script need no other things than itself
- **External Dependencies** (ex. python from Xcode, packages from brew, ports)\
  Must run on stock macOS(BSD) utilies only

Except that, any PR will be appreciated!

