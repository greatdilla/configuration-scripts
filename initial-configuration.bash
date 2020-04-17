#!/usr/bin/env bash
# config: utf-8

#####
## YOU MAY CUSTOMIZE HERE, MAKE SURE YOU KNOW WHAT YOU'RE DOING
SSSSHDPORT=1222
## STOP! NO MORE EDITS BELOW THIS LINE, AS MUCH AS POSSIBLE
#####

## text decoration
WHITE="\033[0;37m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
Off='\E[0m'
Bold='\E[1m'
Dim='\E[2m'
Underline='\E[4m'
Blink='\E[5m'
Reverse='\E[7m'
Strike='\E[9m'
FgBlack='\E[39m'
FgRed='\E[31m'
FgGreen='\E[32m'
FgYellow='\E[33m'
FgBlue='\E[34m'
FgMagenta='\E[35m'
FgCyan='\E[36m'
FgWhite='\E[37m'
BgBlack='\E[40m'
BgRed='\E[41m'
BgGreen='\E[42m'
BgYellow='\E[43m'
BgBlue='\E[44m'4
BgMagenta='\E[45m'
BgCyan='\E[46m'
BgWhite='\E[47m'
FgLtBlack='\E[90m'
FgLtRed='\E[91m'
FgLtGreen='\E[92m'
FgLtYellow='\E[93m'
FgLtBlue='\E[94m'
FgLtMagenta='\E[95m'
FgLtCyan='\E[96m'
FgLtWhite='\E[97m'
BgLtBlack='\E[100m'
BgLtRed='\E[101m'
BgLtGreen='\E[102m'
BgLtYellow='\E[103m'
BgLtBlue='\E[104m'
BgLtMagenta='\E[105m'
BgLtCyan='\E[106m'
BgLtWhite='\E[107m'



function initSystem() {
    echo -e "Preparing the VPS for setup..${NC}"
    DEBIAN_FRONTEND=noninteractive sudo apt-get update
    DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq upgrade

    echo -e "Installing required packages, it may take some time..${NC}"
    sudo apt-get update >/dev/null 2>&1
    #apt-get install fail2ban -y >/dev/null 2>&1
    sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ufw fail2ban >/dev/null 2>&1

    if [ "$?" -gt "0" ] ; then
        echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
        echo "sudo apt-get update"
        echo "sudo apt-get -y upgrade"
        echo "sudo apt -y install ufw fail2ban"
    fi
    #clear
}

function checkV18() {
    ## or try option: -rs or -d
    DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq install lsb-release >/dev/null 2>&1
    if [[ $(lsb_release -rs) != 18.0* ]]; then
        echo -e "${RED}You are not running Ubuntu 18 LTS. Installation is aborted.${NC}"
        exit 18
    fi
}

function checkV16() {
    ## or try option: -rs or -d
    DEBIAN_FRONTEND=noninteractive sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y -qq install lsb-release >/dev/null 2>&1
    if [[ $(lsb_release -rs) != 16.0* ]]; then
        echo -e "${RED}You are not running Ubuntu 16 LTS. Installation is aborted.${NC}"
        exit 16
    fi
}

function checkRoot() {
    ## run-as root?
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}$0 must be run as root.${NC}"
        exit 1
    fi
}

function enableUFW() {
    ## assumes ufw and fail2ban already installed
    sudo ufw --force reset
    sudo ufw --force enable
    sudo ufw default allow outgoing
    sudo ufw default deny incoming
    sudo ufw limit 22/tcp
    ## add your custom SSHD port here
}

function customSsshd() {
    ## allow/limit the custom sshd port in the firewall
    [ $# -ge 1 ] && sudo ufw limit ${1}/tcp
    createSsshdPatch

    ## try 'tail -n 1' in place of grep
    DRYRUN=$( patch -t --dry-run -u $SSSSHDCFG -i $SSSSHDPATCH | grep FAILED)
    [[ $DRYRUN != *FAILED* ]] && ( patch -t -u $SSSSHDCFG -i $SSSSHDPATCH )
}

function removeSsshdPatch() {
    ## remove the patch file
    [ -f $SSSSHDPATCH ] && rm $SSSSHDPATCH
}

function createSsshdPatch() {
    cat << EOF > $SSSSHDPATCH
--- sshd_config-bak     2020-04-17 09:45:59.981611538 +0800
+++ sshd_config 2020-04-17 10:15:37.931610859 +0800
@@ -2,7 +2,7 @@
 # See the sshd_config(5) manpage for details

 # What ports, IPs and protocols we listen for
-#Port 22
+Port ${SSSSHDPORT}
 # Use these options to restrict which interfaces/protocols sshd will bind to
 #ListenAddress ::
 #ListenAddress 0.0.0.0
EOF
}

function fbackUp() {
    ## requires an argument
    DSTAMP=$(date +%Y%m%d)

    if [[ $# -eq 0 ]] ; then
        echo -e "${RED}ALERT: $0 requres an argument (missing filename?).${NC}"
        exit 99
    elif [ ! -f $1 ] ; then
        echo -e "${RED}ERROR: $1 could not be found.${NC}"
        exit 255
    fi

    THISDIR=$(dirname $1)
    THISFILE=$(basename $1)
    cp -p $THISDIR/$THISFILE{,-$DSTAMP}

}

function cleanUp() {
    removeSsshdPatch
}


SSSSHDPATCH=/tmp/.sshd.patch
SSSSHDCFG=/etc/ssh/sshd_config

#checkV16
checkV18
initSystem
enableUFW
fbackUp /etc/ssh/sshd_config && \
    customSsshd ${SSSSHDPORT}

## cleanup
cleanUp


# RUN THIS SCRIPT DIRECTLY!
# bash <(curl https://raw.githubusercontent.com/greatdilla/configuration-scripts/master/initial-configuration.bash)
