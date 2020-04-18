#!/usr/bin/env bash
# * updates the GeoIP.dat file
# * downloads the latest dat file from maxmind.net
# * thanks to Miyuru who keeps this updated

CTRYGEOIP=https://dl.miyuru.lk/geoip/maxmind/country/maxmind.dat.gz
CITYGEOIP=https://dl.miyuru.lk/geoip/maxmind/city/maxmind.dat.gz

THISDIR=$(dirname $0)

function getHashOf() {
    #get hash of argument, this time a file
    if [ $# -eq 0 ] ; then
        echo " [!] ERROR: Missing argument (missing filename?)."
    elif [ ! -f $1 ] ; then
        echo " [!] ERROR: Filename not found (check path?)."
    fi

    MD5HASH=$( md5sum $1 | awk '{print $1}' )
    echo $MD5HASH
}

function downloadNewDat() {
    wget -qN $CTRYGEOIP
    [ -f maxmind.dat.gz ] && zcat maxmind.dat.gz > maxmind.dat
}

MD5OLD=$(getHashOf $THISDIR/GeoIP.dat)
MD5NEW=$(getHashOf $THISDIR/maxmind.dat)

if ! [[ $MD5NEW == $MD5OLD ]] ; then
   exec mv $THISDIR/maxmind.dat $THISDIR/GeoIP.dat
fi


# run this: bash <(curl https://github.com/greatdilla/configuration-scripts/raw/master/update-geoip-dat.bash)
