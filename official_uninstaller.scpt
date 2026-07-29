--tell application "Terminal"
--	activate


set the Uninstall_dlg to ("
You are about to uninstall AmpliTube 5 from your computer.
Are you sure you want to continue?

")


display dialog the Uninstall_dlg with title "Uninstall AmpliTube 5" buttons {"No, cancel", "Yes, continue"} default button 2
if the button returned of the result is "Yes, continue" then


	do shell script "sh -c " & "
		#################################################
		# Search for the receipt containing the product ID and remove it
		#################################################

		#MAC OSX 10.6
		rm -Rf /var/db/receipts/com.ikmultimedia.pkg.HammondB-3X.bom
		rm -Rf /var/db/receipts/com.ikmultimedia.pkg.HammondB-3X.plist

		sudo pkgutil --forget com.ikmultimedia.HammondB-3X

		#################################################


		rm -Rf /Applications/AmpliTube\\ 5.app

		rm -Rf /Library/Audio/Plug-Ins/VST/AmpliTube\\ 5.vst
		rm -Rf /Library/Audio/Plug-Ins/VST3/AmpliTube\\ 5.vst3
		rm -Rf /Library/Audio/Plug-Ins/Components/AmpliTube\\ 5.component
		rm -Rf /Library/Application\\ Support/Avid/Audio/Plug-Ins/AmpliTube\\ 5.aaxplugin

		rm -Rf /Library/Application\\ Support/IK\\ Multimedia/AmpliTube\\ 5/AmpliTube\\ 5.app.pak
		rm -f /Library/Application\\ Support/IK\\ Multimedia/AmpliTube\\ 5/AmpliTube\\ 5.pak


		rm -f \"/Library/Documentation/IK Multimedia/AmpliTube 5/AmpliTube 5 User Manual.pdf\"

		#rm -f \"/Library/Preferences/com.ikmultimedia.AmpliTube 5.plist\"

		" with administrator privileges


	do shell script "sh -c " & "

		numFiles=`find /Library/Application\\ Support/IK\\ Multimedia/AmpliTube\\ 5/ -type f -and -not -name \".DS_Store\" | wc -l`
 		 if test $numFiles -eq 0; then
     			rm -Rf /Library/Application\\ Support/IK\\ Multimedia/AmpliTube\\ 5/
 		 fi

		numFiles=`find ~/Documents/IK\\ Multimedia/AmpliTube\\ 5/ -type f -and -not -name \".DS_Store\" | wc -l`
 		 if test $numFiles -eq 0; then
     			sudo rm -Rf ~/Documents/IK\\ Multimedia/AmpliTube\\ 5/
 		 fi

		numFiles=`find /Library/Documentation/IK\\ Multimedia/AmpliTube\\ 5/ -type f -and -not -name \".DS_Store\" | wc -l`
 		 if test $numFiles -eq 0; then
     			rm -Rf /Library/Documentation/IK\\ Multimedia/AmpliTube\\ 5/
 		 fi

	" with administrator privileges


	display dialog "AmpliTube 5 has been successfully uninstalled from your computer." with title "Uninstall AmpliTube 5" buttons {"Finish"} giving up after 10 default button 1

end if