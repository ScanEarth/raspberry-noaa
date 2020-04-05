# NOAA Automated capture using Raspberry PI
Most of the code and setup stolen from: [Instructables](https://www.instructables.com/id/Raspberry-Pi-NOAA-Weather-Satellite-Receiver/)

### New Features!
  - [Meteor M2 full decoding!](METEOR.md)
  - Nginx webserver to show images with preview thumbnails
  - Timestamp and satellite name over every image
  - WXToIMG configured to create several images (HVC,HVCT,MCIR, etc) based on sun elevation
  - Pictures are posted to Twitter. See more at [Vädersat_tweetbot](https://twitter.com/vadersat).

### Install
There's an [install.sh](install.sh) script that does everything at once. If in doubt, see the [install guide](INSTALL.md)

### Hardware setup
Raspberry-noaa runs on Raspberry PI 2 and up. See the [hardware notes](HARDWARE.md)
