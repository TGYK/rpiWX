# rpiWX

Scripts to automagically capture and decode NOAA 15, 18, 18 APT and METEOR-M 2 LRPT images.

Original credit for the scripts goes to [haslettj](https://www.instructables.com/member/haslettj/)
I have used his scripts and heavily modified them for my own use!

These are some poorly written instructions and a list of dependancies to install to get things working.
This whole project assumes you are running on Raspbian, using the RTL-SDR. 



## Apt-get

    sudo apt-get update
    sudo apt-get install libusb-1.0
    sudo apt-get install cmake
    sudo apt-get install sox
    sudo apt-get install at
    sudo apt-get install predict
    sudo apt-get install fpc
    sudo apt-get install libncurses5-dev libncursesw5-dev  
    sudo apt-get install imagemagick
    sudo apt-get install git
    
### May be needed for wxtoimg to run

    sudo apt-get install libxft2:armhf

## Modify files

#### New file at:
    /etc/modprobe.d/no-rtl.conf

With contents:

    blacklist dvb_usb_rtl28xxu
    blacklist rtl2832
    blacklist rtl2830

#### New file at:

    ~/.wxtoimgrc

With contents:

    Latitude: <Your Latitude>
    Longitude: <Your Longitude EAST POSITIVE>
    Altitude: 25

## Wget

#### [wxtoimg](https://wxtoimgrestored.xyz/):

    cd ~
    wget https://wxtoimgrestored.xyz/beta/wxtoimg-armhf-2.11.2-beta.deb
    sudo dpkg -i wxtoimg-armhf-2.11.2-beta.deb

## Gits

#### [rtl-sdr](https://github.com/keenerd/rtl-sdr):

    git clone https://github.com/keenerd/rtl-sdr.git
    cd rtl-sdr/
    mkdir build
    cd build
    cmake ../ -DINSTALL_UDEV_RULES=ON
    make
    sudo make install
    sudo ldconfig
    sudo make install-udev-rules



#### [meteor_demod](https://github.com/dbdexter-dev/meteor_demod):

    git clone https://github.com/dbdexter-dev/meteor_demod.git
    cd meteor_demod
    make
    sudo make install


#### [medet](https://github.com/artlav/meteor_decoder):

    git clone https://github.com/artlav/meteor_decoder.git
    cd meteor_decoder
    ./build_medet.sh
    sudo cp medet /usr/local/bin/

#### [rtl_biast](https://github.com/rtlsdrblog/rtl_biast):

    git clone https://github.com/rtlsdrblog/rtl_biast.git
    cd rtl_biast
    mkdir build
    cd build
    cmake ..
    make
    sudo make install

#### rpiWX

    git clone https://github.com/TGYK/rpiWX.git
    cd rpiWX/weather/predict
    sudo chmod +x *.sh

#### [meteor_rectify](https://github.com/TGYK/meteor_rectify) (Optional)

##### Assumes you have python3 already installed

###### Be sure to enable in receive_and_process_satellite.sh!

    git clone https://github.com/TGYK/meteor_rectify.git
    cd meteor_rectify
    cp rectify.py ../rpiWX/weather/predict
    pip3 install pillow
    pip3 install numpy


Once everything is installed, reboot and plug in your RTL-SDR and run `rtl_test -t` to test that it is functioning properly. Let it warm up for 10-15 minutes and make a note of the average ppm error value for configuration later.

Set up predict by running it for the first time with the command `predict` enter long/lat accordingly. Predict uses north-positive and **WEST-positive**. Google maps supplies north-positive and **EAST-positive**. Keep this in mind and do the math.

Run wxtoimg using "wxtoimg" and accept the ToS. Make sure to have created the file at `~/.wxtoimgrc` with your lat/lon **EAST-positive**.

Make a cron job with `crontab -e` and add the following line:

    1 0 * * * /home/pi/weather/predict/schedule_all.sh

Modify the receive_and_process_satellite.sh script to add your gain values, ppm error, etc

Modify the schedule_satellite.sh script to add your desired elevation and directory if needed

Modify the schedule_all script to add your directory if needed

Optionally, you can kick things off with:

    /home/pi/weather/predict/schedule_all.sh
