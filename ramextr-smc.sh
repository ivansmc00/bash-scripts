#! /bin/bash

#########################################################
### Script created by Manuel Iván San Martín Castillo ###
#########################################################

##### GLOBAL VARIABLES #####
PP="$1";
OUTPUTDIR_TEMP=${PP%/};
OUTPUTDIR="$OUTPUTDIR_TEMP/ramextr_RAM";
RED='\033[0;31m';
GREEN='\033[0;92m';
BLUE='\033[0;36m';
YELLOW='\033[0;93m';
BOLD='\033[1m';
NC='\033[0m';
FILENAME="$(uname -s)-$(uname -n)_$(uname -r)-RAM.mem";
ZIPNAME="$(lsb_release -i -s 2>/dev/null)_$(uname -r)_profile.zip";
TARGZNAME="$(uname -s)-$(uname -n)_$(uname -r)-RAM.tar.gz";


##### ERROR FUNCTION #####
error(){
cat << EOF

USE: ./ramextr-smc.sh output_dir
This script create a RAM memory image of the current system and the profile necesary for Volatility
Example: ./ramextr-smc.sh /root/test

EOF
}


##### Loading function #####
loading(){
while kill -0 $! 2>/dev/null; do
        for i in {1..3};do
                TXT+=".";
                echo -ne "\r$TXT"
                sleep 0.2
        done;

        for i in {1..3};do
                TXT="${TXT%?}";
                echo -ne "\r$TXT"
                sleep 0.2
        done;
done;
echo -ne "\r$TXT - ${GREEN}${BOLD}DONE\n${NC}";
}


##### RAM image memory creation function #####
ramextr(){
rmmod lime 2>/dev/null;
TXT="$NC${BOLD}[#]$BLUE$BOLD Creating RAM image memory${NC}";
insmod "$LIMEPATH" "path=$OUTPUTDIR/$FILENAME format=lime" &
loading;
echo -e "${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD RAM image memory succesfully created at $YELLOW${BOLD}$OUTPUTDIR/$FILENAME${NC}";
}


##### Cloning Lime from GitHub function #####
clonelime(){
sleep 1;
TMP_FILE=$(mktemp);
TXT="$NC${BOLD}[#]$BLUE$BOLD Cloning Lime from GitHub${NC}";
rm -rf /root/LiME 2>/dev/null;
cd /root && git clone https://github.com/504ensicsLabs/LiME.git 2>"$TMP_FILE";
status_make=$?
wait &
loading;
if [ $status_make -ne 0 ]; then
	echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] Lime download process failed\n${NC}";
	echo -e "$(cat $TMP_FILE)\n";
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] Fix this error and run the script again\n${NC}";
	rm -rf "$TMP_FILE" 2>/dev/null;
	rm -rf /root/LiME 2>/dev/null;
	exit;
else
	echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Lime succesfully cloned from GitHub${NC}";
fi;
rm -rf "$TMP_FILE";
}


##### Compiling Lime function #####
compilelime(){
TXT="$NC${BOLD}[#]$BLUE$BOLD Compiling Lime module${NC}";
cd /root/LiME/src && make >/dev/null 2>&1;
status_make=$?;
wait &
loading;
if [ $status_make -ne 0 ]; then
	echo -e "${BOLD}[$RED${BOLD}-$NC${BOLD}] Lime compiling process failed\n${NC}";
	echo -e "$(cat $TMP_FILE)\n${NC}";
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] Fix this error and run the script again\n${NC}";
	rm -rf "$TMP_FILE" 2>/dev/null;
	cd $OUTPUTDIR && touch ".interrupted_flag";
	exit;
else
	LIMEPATH="/root/LiME/src/lime-$(uname -r).ko";
	echo -e "${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Lime module succesfully compiled and can be found at ${YELLOW}${BOLD}$LIMEPATH${NC}";
fi;
rm -rf "$TMP_FILE" 2>/dev/null;
}


##### Cloning Volatility from GitHub function #####
clonevol(){
sleep 1;
TMP_FILE=$(mktemp);
TXT="$NC${BOLD}[#]$BLUE$BOLD Cloning Volatility from GitHub${NC}";
rm -rf /root/volatility 2>/dev/null;
cd /root && git clone https://github.com/volatilityfoundation/volatility.git 2>"$TMP_FILE";
status_make=$?
wait &
loading;
if [ $status_make -ne 0 ]; then
	echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] Volatility download process failed\n${NC}";
	echo -e "$(cat $TMP_FILE)\n";
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] Fix this error and run the script again\n${NC}";
	rm -rf "$TMP_FILE" 2>/dev/null;
	rm -rf /root/volatility 2>/dev/null;
	cd $OUTPUTDIR && touch ".interrupted_flag";
	exit;
else
	echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Volatility Framework succesfully cloned from GitHub${NC}";
fi;
rm -rf "$TMP_FILE";
}


##### Compiling Volatility Framework function #####
compilevol(){
sleep 1;
TMP_FILE=$(mktemp);
TXT="$NC${BOLD}[#]$BLUE$BOLD Compiling Volatility Framework${NC}";
cd /root/volatility/tools/linux && make >"$TMP_FILE" 2>&1;
status_make=$?
wait &
loading;
if [ $status_make -ne 0 ]; then
	echo -e "${BOLD}[$RED${BOLD}-$NC${BOLD}] Volatility compiling process failed\n${NC}";
	echo -e "$NC$(cat $TMP_FILE)\n";
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] Fix this error and run the script again\n${NC}";
	rm -rf "$TMP_FILE" 2>/dev/null;
	cd $OUTPUTDIR && touch ".interrupted_flag";
	exit;
else
	echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Volatility Framework succesfully compiled${NC}";
fi;
rm -rf "$TMP_FILE";
}

##### Check user root and no positional parameter #####
([ $EUID -ne 0 ]) && error && echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] This script must be run as root\n${NC}" && exit;
([ $# -ne 1 ]) && error && exit;


##### Check $1 is absolute path #####
if ! [ "$(echo ${1:0:1})" == "/" ]; then
	error;
	echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] output_dir value must be an absolute path\n${NC}";
	exit 1;
fi;


##### Check network connectivity #####
ping -c 1 8.8.8.8 > /dev/null 2>&1
([ $? -ne 0 ]) && error && echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] Internet connection it's necessary to run the script\n${NC}" && exit;

echo;


if [ -f "$OUTPUTDIR/.interrupted_flag" ]; then
	echo -e "${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD RAM memory image already exists, skipping...${NC}";
else
	if [ ! -d "$OUTPUTDIR" ]; then
		mkdir -p $OUTPUTDIR 2>/dev/null;
	else
		echo -e "${BOLD}[$RED${BOLD}-$NC${BOLD}] Directory ${YELLOW}${BOLD}$1 ${NC}${BOLD}already exists\n${NC}";
		exit 1;
	fi;

	TXT="$NC${BOLD}[#]$BLUE$BOLD Searching Lime Module";
	TMP_FILE=$(mktemp);
	find / -type f -name "lime-$(uname -r).ko" > "$TMP_FILE" 2>/dev/null &
	loading;
	LIMEPATH=$(cat "$TMP_FILE");
	rm "$TMP_FILE";
	if [ -n "$LIMEPATH" ]; then
		echo -e "${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Lime module found at ${YELLOW}${BOLD}$LIMEPATH${NC}";
		ramextr;
		cd $OUTPUTDIR && touch ".interrupted_flag";
	else
		echo -e "${BOLD}[$RED${BOLD}-$NC${BOLD}]$BLUE$BOLD No Lime module found, creating a new one${NC}";
		clonelime;
		compilelime;
		ramextr;
		cd $OUTPUTDIR && touch ".interrupted_flag";
	fi;
fi;


##### Check Volatility integrity #####
if [ -d "/root/volatility" ]; then
	echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Volatility Directory found in ${YELLOW}${BOLD}/root/volatility${NC}";
	if [ -f "/root/volatility/tools/linux/module.dwarf" ]; then
		echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Module${YELLOW}${BOLD} module.dwarf ${BLUE}${BOLD}found in Volatility Directory${NC}";
	else
		compilevol;
	fi;
else
	clonevol;
	compilevol;
fi;


##### Custom profile creation #####
TXT="$NC${BOLD}[#]$BLUE$BOLD Creating custom profile for Volatility Framework${NC}";
zip "$ZIPNAME" /root/volatility/tools/linux/module.dwarf /boot/System.map-$(uname -r) 1>/dev/null &
loading;
echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Custom profile succesfully created at ${YELLOW}${BOLD}$OUTPUTDIR/$ZIPNAME${NC}";
mv $ZIPNAME $OUTPUTDIR;


##### Files compression #####
TXT="$NC${BOLD}[#]${BLUE}${BOLD} Compressing ${YELLOW}${BOLD}$OUTPUTDIR ${BLUE}${BOLD}content${NC}";
tar -czf $TARGZNAME $OUTPUTDIR 2>/dev/null &
loading;
mv $TARGZNAME $OUTPUTDIR;
echo -e "$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Files succesfully compressed at ${YELLOW}${BOLD}$OUTPUTDIR/$TARGZNAME${NC}";
cd $OUTPUTDIR && rm ".interrupted_flag" 2>/dev/null;
echo -e "\n$NC${BOLD}[$GREEN${BOLD}+$NC${BOLD}]$BLUE$BOLD Script succesfully completed. Files stored in ${YELLOW}${BOLD}$OUTPUTDIR${NC}\n";

exit 0;
