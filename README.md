# rpiWX

Scripts to automagically capture and decode weather satellites

These are some poorly written instructions and a list of dependancies to install to get things working.
This whole project assumes you are running on Raspbian, using the RTL-SDR. 



## Apt-get

    sudo apt-get install libusb-1.0
    sudo apt-get install cmake
    sudo apt-get install sox
    sudo apt-get install at
    sudo apt-get install predict
    sudo apt-get install libglib2.0-dev
    sudo apt-get install fpc
    sudo apt-get install libncurses5-dev libncursesw5-dev  

## Modify files

#### New file at:
    /etc/modprobe.d/no-rtl.con

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

#### New directory at:

    ~/weather

#### New directory at:

    ~/weather/predict

## Wget

#### wxtoimg:

    cd ~
    wget https://wxtoimgrestored.xyz/beta/wxtoimg-armhf-2.11.2-beta.deb
    sudo dpkg -i wxtoimg-armhf-2.11.2-beta.deb

## Gits

#### rtl-sdr:

    git clone https://github.com/keenerd/rtl-sdr.git
    cd rtl-sdr/
    mkdir build
    cd build
    cmake ../ -DINSTALL_UDEV_RULES=ON
    make
    sudo make install
    sudo ldconfig
    cd ~
    sudo cp ./rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/

#### libgpredict:

    git clone https://github.com/cubehub/libgpredict.git
    cd libgpredict
    mkdir build
    cd build
    cmake ../
    make
    make install
    sudo ldconfig


#### meteor_demod:

    git clone https://github.com/dbdexter-dev/meteor_demod.git
    cd meteor_demod
    make
    sudo make install


#### medet:

    git clone https://github.com/artlav/meteor_decoder.git
    cd meteor_decoder
    ./build_medet.sh
    sudo cp medet /usr/local/bin/

#### rtl_biast:

    git clone https://github.com/rtlsdrblog/rtl_biast
    cd rtl_biast
    mkdir build
    cd build
    cmake ..
    make
    sudo make install


Once everything is installed, plug in your RTL-SDR and run rtl_test -t to test that it is functioning properly. Let it warm up because the ppm value is important for later.

Set up predict by running it for the first time with the command `predict` enter long/lat accordingly. Predict uses north-positive and WEST-positive. Google maps supplies north-positive and EAST-positive. Keep this in mind and do the math.

Run wxtoimg using "wxtoimg" and accept the ToS. Make sure to have created the file at `~/.wxtoimgrc` with your lat/lon EAST-positive.

Place the three scripts in `~/weather/predict/` and enable execution on them with `sudo chmod +x <scriptname>`

Make a cron job with "crontab -e" and add the following line:

    1 0 * * * /home/pi/weather/predict/schedule_all.sh

Modify the receive_and_process_satellite.sh script to add your gain values, etc
Modify the schedule_satellite.sh script to add your desired elevation

Optionally, you can kick things off with:

    /home/pi/weather/predict/schedule_all.sh
