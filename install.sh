#!/bin/bash
set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

die() {
    >&2 echo "${RED}error: $1${RESET}" && exit 1
}

log() {
    echo "$*"
}

log_done() {
    echo " ${GREEN}✓${RESET} $1"
}

log_running() {
    echo " ${YELLOW}*${RESET} $1"
}

success() {
    echo "${GREEN}$1${RESET}"
}

### Verify cloned repo
if [ ! -e "$HOME/raspberry-noaa" ]; then
        die "Is https://github.com/ScanEarth/raspberry-noaa cloned in your home directory?"
fi

### Install required packages
log_running "Installing required packages..."
sudo apt update -yq
sudo apt install -yq predict \
                     python-setuptools \
                     ntp \
                     cmake \
                     libusb-1.0 \
                     sox \
                     at \
                     bc \
                     nginx \
                     libncurses5-dev \
                     libncursesw5-dev \
                     libatlas-base-dev \
                     python3-pip \
                     imagemagick \
                     libxft-dev \
                     libxft2

sudo pip3 install numpy ephem tweepy Pillow
log_done "Packages installed"

### Blacklist DVB modules
if [ -e /etc/modprobe.d/rtlsdr.conf ]; then
    log_done "DVB modules were already blacklisted"
else
    sudo cp templates/modprobe.d/rtlsdr.conf /etc/modprobe.d/rtlsdr.conf
    log_done "DVB modules are blacklisted now"
fi

### Install RTL-SDR
if [ -e /usr/local/bin/rtl_fm ]; then
    log_done "rtl-sdr was already installed"
else
    log_running "Installing rtl-sdr from osmocom..."
    (
        cd /tmp/
        git clone https://github.com/osmocom/rtl-sdr.git
        cd rtl-sdr/
        mkdir build
        cd build
        cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
        make
        sudo make install
        sudo ldconfig
        cd /tmp/
        sudo cp ./rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/
    )
    log_done "rtl-sdr install done"
fi

### Install WxToIMG
if [ -e /usr/local/bin/xwxtoimg ]; then
    log_done "WxToIMG was already installed"
else
    log_running "Installing WxToIMG..."
    sudo dpkg -i software/wxtoimg-armhf-2.11.2-beta.deb
    log_done "WxToIMG installed"
fi

### Install default config file
if [ -e "$HOME/.noaa.conf" ]; then
    log_done "$HOME/.noaa.conf already exists"
else
    cp "templates/noaa.conf" "$HOME/.noaa.conf"
    log_done "$HOME/.noaa.conf installed"
fi

if [ -e "$HOME/.predict/predict.qth" ]; then
    log_done "$HOME/.predict/predict.qth already exists"
else
    cp "templates/predict.qth" "$HOME/.predict/predict.qth"
    log_done "$HOME/.predict/predict.qth installed"
fi

if [ -e "$HOME/.wxtoimgrc" ]; then
    log_done "$HOME/.wxtoimgrc already exists"
else
    cp "templates/wxtoimgrc" "$HOME/.wxtoimgrc"
    log_done "$HOME/.wxtoimgrc installed"
fi

if [ -e "$HOME/.tweepy.conf" ]; then
    log_done "$HOME/.tweepy.conf already exists"
else
    cp "templates/tweepy.conf" "$HOME/.tweepy.conf"
    log_done "$HOME/.tweepy.conf installed"
fi

### Install meteor_demod
if [ -e /usr/bin/meteor_demod ]; then
    log_done "meteor_demod was already installed"
else
    log_running "Installing meteor_demod..."
    (
        cd /tmp
        git clone https://github.com/dbdexter-dev/meteor_demod.git
        cd meteor_demod
        make
        sudo make install
    )
    log_done "meteor_demod installed"
fi

### Install medet_arm
if [ -e /usr/bin/medet_arm ]; then
    log_done "medet_arm was already installed"
else
    log_running "Installing medet_arm..."
    sudo cp software/medet_arm /usr/bin/medet_arm
    sudo chmod +x /usr/bin/medet_arm
    log_done "medet_arm installed"
fi

### Cron the scheduler
crontab -l | grep -q "raspberry-noaa"
if [ $? -eq 0 ]; then
    log_done "Crontab for schedule.sh already exists"
else
    cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa/schedule.sh") | crontab -
    log_done "Crontab installed"
fi

### Setup Nginx
log_running "Setting up Nginx..."
sudo cp templates/nginx.cfg /etc/nginx/sites-enabled/default
(
    sudo mkdir -p /var/www/wx
    sudo chown -R www-data:www-data /var/www/wx
    sudo usermod -a -G www-data pi
    sudo chmod 775 /var/www/wx
)
sudo systemctl restart nginx
if [ ! -e /var/www/wx/index.html ]; then
    cp templates/index.html /var/www/wx/index.html
fi
log_done "Nginx configured"

### Setup ramFS
cat /etc/fstab | grep -q "ramfs"
if [ $? -eq 0 ]; then
    log_done "ramfs already setup"
else
    sudo mkdir -p /var/ramfs
    cat templates/fstab | sudo tee -a /etc/fstab > /dev/null
    log_done "Ramfs installed"
fi
set +e
sudo mount -a
set -e
sudo chmod 777 /var/ramfs

success "Install (almost) done!"
echo "
    It's time to configure your ground station
    You'll be asked for your latitude and longitude
    Use negative values for South and West
    "

read -rp "Enter your latitude (South values are negative): "
        lat=$REPLY

read -rp "Enter your longitude (West values are negative): "
        lon=$REPLY

sed -i -e "s/change_latitude/${lat}/g;s/change_longitude/${lon}/g" "$HOME/.noaa.conf"
sed -i -e "s/change_latitude/${lat}/g;s/change_longitude/${lon}/g" "$HOME/.wxtoimgrc"
sed -i -e "s/change_latitude/${lat}/g;s/change_longitude/$(echo  "$lon * -1" | bc)/g" "$HOME/.predict/predict.qth"
sed -i -e "s/change_latitude/${lat}/g;s/change_longitude/${lon}/g" "sun.py"


success "Install done! Double check your $HOME/.noaa.conf settings"

echo "
    If you want to post your images to Twitter, please setup
    your Twitter credentials on $HOME/.tweepy.conf
"
