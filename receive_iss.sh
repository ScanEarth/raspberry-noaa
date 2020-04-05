#!/bin/sh
datetime=$(date +"%Y%m%d-%H%M%S")
sudo systemctl stop dump1090-mutability.service
timeout 660 /usr/local/bin/rtl_fm -M fm -f 145.8M -s 48k -T -g ${GAIN} -p ${PPM} -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 48000 - /usr/share/html/iss/iss-$datetime.wav rate 11025
sudo systemctl start dump1090-mutability.service
