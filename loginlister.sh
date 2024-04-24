#!/bin/bash

#########################################################
### Script created by Manuel Iván San Martín Castillo ###
#########################################################


#---------- GLOBAL VARIABLES ----------#


RED='\033[0;31m';
GREEN='\033[0;92m';
BLUE='\033[0;36m';
YELLOW='\033[0;93m';
DARKGREY='\e[90m';
MAGENTA='\e[95m';
BOLD='\033[1m';
UNDERLINED='\e[4m';
NC='\033[0m';
GAU_TOML="$HOME/.gau.toml";
SIMPLENAME="$(basename $1 | cut -d '.' -f1)";
PROJECTNAME="loginlister_$SIMPLENAME";
URLFILE="listurl_${SIMPLENAME}.txt";
LOGINFILE="login-list_${SIMPLENAME}.txt";
GETPARAMFILE="get-param-list_${SIMPLENAME}.txt";
TMPFILE="tmp-file_${SIMPLENAME}.txt";
WPPLUGINFILE="wpplugin-list_${SIMPLENAME}.txt"
UNKNOWN="${RED}${BOLD}UNKNOWN${NC}";
VULN="$UNKNOWN";
VERSION_VULN="$UNKNOWN";


#---------- ERROR FUNCTION ----------#


error(){
cat << EOF

USE: ./loginlister.sh DOMAIN_LIST.txt
This script create a simple file with all login pages found indexed in the domains provided

EOF
}


#---------- GAU CONFIG ----------#


cat << EOF > "$GAU_TOML"
threads = 2
verbose = false
retries = 15
subdomains = true
parameters = false
providers = ["wayback","commoncrawl","otx","urlscan"]
blacklist = []
json = false

[urlscan]
  apikey = "b49308e7-4d2d-46ce-af05-f37d39cef815"

[filters]
  from = ""
  to = ""
  matchstatuscodes = []
  matchmimetypes = []
  filterstatuscodes = []
  filtermimetypes = []
EOF


#---------- LOADING FUNCTION ----------#


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

#---------- VULNERABILITY CHECK FUNCTION ----------#


vuln_check(){
declare -g VERSION_VULN
declare -g VULN
declare -g UNKNOWN

local EXPLOIT="$1";

VERSION_VULN=$(echo $EXPLOIT | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?');
	if [[ -z $VERSION_VULN ]]; then
        	VERSION_VULN="$UNKNOWN";
	fi;

	if [[ -n "$(echo $EXPLOIT | awk -F' ' '{print $3}' | grep '-')" ]]; then
		VULN=$(echo "$EXPLOIT" | awk '{gsub("-", "_", $3); print}' | rev | awk -F"-" '{print $1}' | rev | sed 's/ //');
	else
		VULN=$(echo "$EXPLOIT" | cut -d'-' -f2- | sed 's/ //');
	fi;
}


stop_bg_ps() {
    kill $(jobs -p) 2>/dev/null
}

trap 'stop_bg_ps; exit 1' SIGINT


#---------- CHECK FOR SCRIPT RUNNING AS ROOT AND ONLY ONE POSITIONAL PARAMETER ----------#


([ $EUID -ne 0 ]) && error && echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] This script must be run as root${NC}" && exit;
([ $# -ne 1 ]) && error && exit;


#---------- CHECK FOR INTERNET CONNECTION ----------#


ping -c 1 8.8.8.8 > /dev/null 2>&1
([ $? -ne 0 ]) && error && echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] Internet connection it's necessary to run the script\n${NC}" && exit;


#---------- CHECK IF FILE INTRODUCED IS A VALID TXT FILE TO AVOID PROBLEMS ----------#


if [[ -f "$1" ]]; then
	TYPE=$(file -b --mime-type "$1");
	if [[ "$TYPE" != "text/plain" ]]; then
		echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] $1 is not a valid file${NC}" && exit;
	fi;
else
	echo -e "\n${BOLD}[$RED${BOLD}-$NC${BOLD}] $1 is not a file${NC}" && exit;
fi;


#---------- DETECT FOR AN ALREADY EXISTING PROJECT AND PRESENCE OF resume.cfg FILE TO ----------#


echo;
if ([ -d $PROJECTNAME ] && [ ! -f "$PROJECTNAME/resume.cfg" ]); then
	while true; do
		echo -ne "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] A project for $1 is already created ¿Do you want to overwrite it? (Y/N) ${NC}";
		read  OVERWRITE;
		case $OVERWRITE in
			Y|y|s|S)
				rm -rf $PROJECTNAME/*
				break;
			;;
			N|n)
				break;
			;;
			*)
			;;
		esac;
	done;
else
	mkdir $PROJECTNAME 2>/dev/null;
fi;


#---------- CHECK IF URLFILE IS ALREADY OBTAINED (List with all endpoints) ----------#


if [ ! -f "$PROJECTNAME/$URLFILE" ]; then
	TXT="$NC${BOLD}[#]$BLUE$BOLD Searching endpoints from domains provided with gau${NC}";
	cat $1 | gau --o $PROJECTNAME/$TMPFILE &
	loading;

	TXT="$NC${BOLD}[#]$BLUE$BOLD Searching endpoints from domains provided with linkfinder${NC}";
	{
		cat $PROJECTNAME/$TMPFILE | awk -F"/" '{print $1,$2,$3}' | sed 's/ /\//g' | sed 's/:80//g' | awk -F"?" '{print $1}' | sed 's/ //g' | sort -u >> $PROJECTNAME/tmp.txt
		for URL in $(cat $PROJECTNAME/tmp.txt | sort -u); do
			linkfinder -i "$URL" -d -o cli | egrep -v "against|http|Error:|Usage:|" | sed '/^$/d' | sed 's/^\.//' | sed 's/^[^/]/\/&/' | sed -e "s|^|$URL|" >> $PROJECTNAME/tmp2.txt
		done;
		cat $PROJECTNAME/tmp2.txt >> $PROJECTNAME/$TMPFILE;
		cat $PROJECTNAME/$TMPFILE | sort -u  >> $PROJECTNAME/$URLFILE;
	} &
	loading;
	rm $PROJECTNAME/$TMPFILE
	rm $PROJECTNAME/tmp.txt
	rm $PROJECTNAME/tmp2.txt
	URL="";
else
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] Endpoints have been obtained already ${NC}- $YELLOW${BOLD}SKIPPING${NC}";
fi;


#---------- CHECK IF LOGINFILE IS ALREADY OBTAINED (List with all login pages in superficial mode) ----------#


if [ ! -f "$PROJECTNAME/$LOGINFILE" ]; then
	TXT="$NC${BOLD}[#]$BLUE$BOLD Creating a list with logins${NC}";

	{
		awk -F'[?;]' '{print $1}' $PROJECTNAME/$URLFILE | awk -F"%3F" '{print $1}' | grep -viE '\.(webp|png|jpg|jpeg|gif|mp3|mp4|svg|woff2?|eot|otf|ttf|css|exe|js|pdf|ctrl|swf|ico|axd|xml)|/(css|images|javascript|js)/|(%2Flogin|nologin|no-login|no_login|logout|log-out|log_out|logoff|log-off|log_off|signup|sign-up|sign_up|indexof|post|lost|recovery|forgot|reset|pass|cookie|email|head|forfait|propo|info|mention|clear|search|flash|feed|microsoft|candidat|announ|news|about|over|robot|style|term|regis|subscr|faq|font|error|redirect|agenda|deconnexion|jquery|[kc]onta[kc]|[kc]atalog)' | grep -iE '(login|log-in|log_in|logon|log-on|log_on|sign-on|signon|signin|sign-in|sign_in|home|default\.|welcome.cgi|accueil|/index/|index\.*|admin|verwaltung|dashboard|[kc]ontrolpanel|panel|paneel|pannello|painel|haldus|hallinta|backoffice|console|beheer|hallinta|anmelden|%D0%BB%D0%BE%D0%B3%D0%B8%D0%BD|%D0%92%D1%85%D0%BE%D0%B4|connexion|entrar|accedi|logga|prijava|eisodos|roguin|intranet|extranet|menu|system|report)' | sed 's/:80//g' | sed 's/\/$//g' | sort -u > $PROJECTNAME/$TMPFILE
		awk -F'[?;]' '{print $1}' $PROJECTNAME/$URLFILE | awk -F"%3F" '{print $1}' | grep -viE '\.(webp|png|jpg|jpeg|gif|mp3|mp4|svg|woff2?|eot|otf|ttf|css|exe|js|pdf|ctrl|swf|ico|axd|xml)|/(css|images|javascript|js)/|jquery' | sed 's/:80//g' | awk -F"/" '{print $1,$2,$3}' | sed 's/ /\//g' | sed 's/\/$//g'|sort -u >> $PROJECTNAME/$TMPFILE
		cat $PROJECTNAME/$TMPFILE | httpx -silent -mc 200 -mr 'name="(user|username|usr|us3r|login|usu)"&name="(pass|password|pss|pwd|passwd|contr|clave)"|type="password"' >> $PROJECTNAME/$LOGINFILE
	} &
	loading;

	rm $PROJECTNAME/$TMPFILE;
else
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] List with logins have been obtained already ${NC}- $YELLOW${BOLD}SKIPPING${NC}";
fi;


#---------- CHECK IF GETPARAMFILE IS ALREADY OBTAINED (List with all URL's that include a GET parameter) ----------#


if [ ! -f "$PROJECTNAME/$GETPARAMFILE" ]; then
	TXT="$NC${BOLD}[#]$BLUE$BOLD Creating a list with GET parameter in URL${NC}";
	{
		cat $PROJECTNAME/$URLFILE | grep -iE "\?(file|page|template|dir|path|folder|config|theme|style|skin|content|view|id|mode|user|pass|search|category|product|path|sql)\=*"  > $PROJECTNAME/$TMPFILE;
		for URL in $(cat $PROJECTNAME/$TMPFILE | sed 's/:80//g' | awk -F"?" '{print $1}' | sed 's/\/$//g' | sort -u); do
			cat $PROJECTNAME/$TMPFILE | grep $URL | awk '{print length, $0}' | sort -rn | cut -d' ' -f2 | head -n 1 >> $PROJECTNAME/tmp.txt;
		done;
		cat $PROJECTNAME/tmp.txt | httpx -silent -fr -mc 200 >> $PROJECTNAME/$GETPARAMFILE
	} &
	loading;

	rm $PROJECTNAME/$TMPFILE;
	rm $PROJECTNAME/tmp.txt;
else
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] List with GET parameter in URL have been obtained already ${NC}- $YELLOW${BOLD}SKIPPING${NC}";
fi;


#---------- CHECK IF WPPLUGINFILE IS ALREADY OBTAINED (List with all URL's that include WordPress Plugins and vulnerabilities) ----------#


if [ ! -f "$PROJECTNAME/$WPPLUGINFILE" ]; then
	TXT="$NC${BOLD}[#]$BLUE$BOLD Creating a list with WordPress Plugins${NC}";
	echo -e "\n\t\t${BOLD}${UNDERLINED}URL\t\tPlugin\t\tVersion | ExploitVersion\t\tVulnerability\t\tStatus\t\tExploit\n" > $PROJECTNAME/$WPPLUGINFILE
	{
		cat $PROJECTNAME/$URLFILE | grep "/wp-content/plugins/" | awk -F"/" '{print $1,$2,$3}' | sed 's/ /\//g' | sed 's/:80//g' | sort -u  > $PROJECTNAME/$TMPFILE
		for URL in $(cat "$PROJECTNAME/$TMPFILE" | awk -F" " '{print $1}'); do
			for PLUGIN in $(cat $PROJECTNAME/$URLFILE | grep $URL | grep "wp-content/plugins/" | awk -F"wp-content/plugins/" '{print $2}' | awk -F "/" '{print $1}' | sort -u); do
				OLDIFS=$IFS;
				IFS=$'\n';
				SS=$(searchsploit wordpress plugin "$PLUGIN" | grep -i "wordpress" 2>/dev/null);
				for LINE in $(echo "$SS" | tr -s " " | sed 's/$/\n/'); do
					VERSION="$UNKNOWN";
					VERSION_VULN="$UNKNOWN";
                                        VULN="$UNKNOWN";
					EXPLOIT=$(echo $LINE | rev | cut -d"|" -f2- | rev | grep -i "wordpress");
					EXPLOITFILE=$(echo $LINE | rev | awk -F"|" '{print $1}' | rev | sed 's/ //');
					CURRENTURL=$(cat "$PROJECTNAME/$URLFILE" | grep "$URL" | grep "/wp-content/plugins/$PLUGIN/");
					if echo "$CURRENTURL" | grep -q "ver"; then
						VERSION="$(echo $CURRENTURL | tr ' ' '\n' | grep  'ver' | awk -F'=' '{print $2}' | awk -F'&' '{print $1}' | sort -Vur | head -n 1)";
						if [[ ! "$VERSION" =~ \. ]]; then
							VERSION="$UNKNOWN";
						fi;

						if [[ -n $SS ]]; then
							vuln_check "$EXPLOIT"
							if [[ ("$VERSION_VULN" != "$UNKNOWN") || ("$VERSION" != "$UNKNOWN") ]]; then
								if [[ "$VERSION_VULN" == "$VERSION" ]]; then
									echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${GREEN}${BOLD}$VERSION${NC}|${GREEN}${BOLD}$VERSION_VULN${NC} - ${MAGENTA}${BOLD}$VULN${NC} ${BOLD}[${GREEN}${BOLD}EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
								elif [[ "$VERSION_VULN" > "$VERSION" ]]; then
									echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${DARKGREY}${BOLD}$VERSION${NC}|${GREEN}${BOLD}$VERSION_VULN${NC} - ${MAGENTA}${BOLD}$VULN${NC} ${BOLD}[${YELLOW}${BOLD}POSSIBLY EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
								else
									echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${DARKGREY}${BOLD}$VERSION${NC}|${GREEN}${BOLD}$VERSION_VULN${NC} - ${MAGENTA}${BOLD}$VULN${NC} ${BOLD}[${RED}${BOLD}NO EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
								fi;
							else
								echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${RED}${BOLD}$VERSION${NC}|${RED}${BOLD}$VERSION_VULN${NC} - ${MAGENTA}${BOLD}$VULN${NC} ${BOLD}[${YELLOW}${BOLD}POSSIBLY EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
							fi;
						else
							if [[ "$VERSION" == "$UNKNOWN" ]]; then
								echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${RED}${BOLD}$VERSION${NC}|${RED}${BOLD}$VERSION_VULN${NC} - ${RED}${BOLD}$VULN${NC} ${BOLD}[${RED}${BOLD}NO EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
							else
								echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${DARKGREY}${BOLD}$VERSION${NC}|${RED}${BOLD}$VERSION_VULN${NC} - ${RED}${BOLD}$VULN${NC} ${BOLD}[${RED}${BOLD}NO EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
							fi;
						fi;
					else
                                        	if [[ -n $SS ]]; then
							vuln_check "$EXPLOIT";
							echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${RED}${BOLD}$VERSION${NC}|${GREEN}${BOLD}$VERSION_VULN${NC} - ${MAGENTA}${BOLD}$VULN${NC} ${BOLD}[${YELLOW}${BOLD}POSSIBLY EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE
						else
							echo -e "${BLUE}${BOLD}$URL${NC} - ${BOLD}$PLUGIN${NC} - ${RED}${BOLD}$VERSION${NC}|${RED}${BOLD}$VERSION_VULN${NC} - ${RED}${BOLD}$VULN${NC} ${BOLD}[${RED}${BOLD}NO EXP${NC}${BOLD}]${NC} ${BOLD}$EXPLOITFILE" >> $PROJECTNAME/$WPPLUGINFILE;
						fi;
					fi;

				done;
			done;
		done;

	} &
	loading;
	IFS=$OLFIFS;
	rm $PROJECTNAME/$TMPFILE;
else
	echo -e "${BOLD}[$YELLOW${BOLD}!$NC${BOLD}] List with WordPress Plugins have been obtained already ${NC}- $YELLOW${BOLD}SKIPPING${NC}";
fi;
