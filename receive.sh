#!/bin/bash


## import common lib
. ~/.noaa.conf
. ~/.tweepy.conf
. "${NOAA_HOME}/common.sh"


## pass start timestamp and sun elevation
PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null
then
	log "There is an existing rtl_fm instance running, I quit" "ERROR"
	exit 1
fi

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

sudo systemctl stop dump1090-mutability.service
timeout "${6}" /usr/local/bin/rtl_fm -f "${2}"M -s 60k -T -g ${GAIN} -p ${PPM} -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 60000 - "${NOAA_AUDIO}/audio/${3}.wav" rate 11025
sudo systemctl start dump1090-mutability.service

if [ ! -d "${NOAA_OUTPUT}/image/${FOLDER_DATE}" ]; then
	mkdir -m 775 -p "${NOAA_OUTPUT}/image/${FOLDER_DATE}"
fi

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
	ENHANCEMENTS="ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT"
else
	ENHANCEMENTS="ZA MCIR MCIR-precip"
fi

/usr/local/bin/wxmap -T "${1}" -H "${4}" -p 0 -g 0.0 -l 0 -o "${PASS_START}" "${NOAA_HOME}/map/${3}-map.png"
for i in $ENHANCEMENTS; do
	/usr/local/bin/wxtoimg -I -n -c -o -m "${NOAA_HOME}/map/${3}-map.png" -e "$i" "${NOAA_AUDIO}/audio/${3}.wav" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-$i.jpg"
	/usr/bin/convert -quality 90 -format jpg "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-$i.jpg" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-$i.jpg"
done
if [ -n "$CONSUMER_KEY" ]; then
	if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
		python3 "${NOAA_HOME}/post.py" "$1 ${START_DATE}" "$7" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MSA-precip.jpg" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVC-precip.jpg" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVCT-precip.jpg" 
	else
		python3 "${NOAA_HOME}/post.py" "$1 ${START_DATE}" "$7" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR.jpg"
	fi
fi

rm "${NOAA_AUDIO}/audio/${3}.wav"
