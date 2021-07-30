# use rpiboot to mount flash drive to computer
# install the Raspberry PI OS Lite using Raspberry PI Imager
# start rpiboot again and disconenct/reconnect USB from PI to computer
# place an empty file called ssh into the boot drive root folder to enable ssh
# flip swtich and reboot, connect to hdmi monitor to get IP address, ssh into unit as pi/raspberry

#now configure cameras, monitor and USB
sudo apt update
sudo apt ugprade
sudo wget https://datasheets.raspberrypi.org/cmio/dt-blob-disp1-cam2.bin -O /boot/dt-blob.bin

sudo apt-get install -y p7zip-full
cd ~
wget https://www.waveshare.com/w/upload/4/41/CM4_dt_blob.7z
7z x CM4_dt_blob.7z -O./CM4_dt_blob
sudo chmod 777 -R CM4_dt_blob
cd CM4_dt_blob/
sudo  dtc -I dts -O dtb -o /boot/dt-blob.bin dt-blob-disp0-double_cam.dts
cd ~
sudo rm -rf CM4_dt_blob.7z
sudo rm -rf CM4_dt_blob
sudo su
echo "#enable USB" >> /boot/config.txt
echo "dtoverlay=dwc2,dr_mode=host" >> /boot/config.txt
#for CM4 Wifi
cd /lib/firmware/brcm
wget https://raw.githubusercontent.com/RPi-Distro/firmware-nonfree/master/brcm/brcmfmac43455-sdio.txt
cp brcmfmac43455-sdio.raspberrypi,4-model-b.txt brcmfmac43456-sdio.raspberrypi,4-compute-module.txt
reboot

#update and upgrade
sudo apt update
sudo apt upgrade
sudo reboot

#now install OpenVINO
curl -O https://storage.openvinotoolkit.org/repositories/openvino/packages/2021.4/l_openvino_toolkit_runtime_raspbian_p_2021.4.582.tgz
sudo mkdir -p /opt/intel/openvino_2021
sudo tar -xf  l_openvino_toolkit_runtime_raspbian_p_2021.4.582.tgz --strip 1 -C /opt/intel/openvino_2021
rm l_openvino_toolkit_runtime_raspbian_p_2021.4.582.tgz

#install pip
sudo apt install -y python3-pip
sudo apt install -y python-pip

#install git
sudo apt install -y git
sudo apt install -y git-lfs

#install protobuf
sudo  apt install -y protobuf-compiler

#now update and install cmake
sudo apt-get install libssl-dev
wget https://github.com/Kitware/CMake/releases/download/v3.21.1/cmake-3.21.1.tar.gz
tar -xvzf cmake-3.21.1.tar.gz
rm cmake-3.21.1.tar.gz
cd cmake-3.21.1
sudo ./bootstrap
sudo make
sudo make install
cd ~
rm -rf cmake-3.21.1

#or just download from repo, unzip and run `sudo make install` then delete the folder and the archive

#finish setup of openVINO
source /opt/intel/openvino_2021/bin/setupvars.sh
echo "source /opt/intel/openvino_2021/bin/setupvars.sh" >> ~/.bashrc

#add USB rules for Intel NCS2
sudo usermod -a -G users "$(whoami)"
sh /opt/intel/openvino_2021/install_dependencies/install_NCS_udev_rules.sh

#download configure and install onnxruntime with support for Intel NCS2/Myriad X
sudo pip3 install wheel
sudo pip3 install Cython
git clone --recursive -b master https://github.com/microsoft/onnxruntime.git

#ensure the Intel NCS2 is plugged into the rPi USB otherwise tests will fail and last a lot longer
#add --arm or --arm64 if compiling on gcc8.3 due to a bug and also set the -latomic flags; see: https://github.com/microsoft/onnxruntime/issues/4189
echo 'string(APPEND CMAKE_CXX_FLAGS " -latomic")' >> ~/onnxruntime/cmake/CMakeLists.txt
echo 'string(APPEND CMAKE_C_FLAGS " -latomic")' >> ~/onnxruntime/cmake/CMakeLists.txt
BUILDTYPE=MinSizeRel
BUILDARGS="--config ${BUILDTYPE} --parallel --arm --use_openvino MYRIAD_FP16 "
sudo /bin/sh onnxruntime/dockerfiles/scripts/install_common_deps.sh
cd ~/onnxruntime/cmake/external/onnx && sudo python3 setup.py install

cd ~/onnxruntime 
#Update and Build
./build.sh ${BUILDARGS} --update --build

# Build Shared Library
./build.sh ${BUILDARGS} --build_shared_lib

# Build Python Bindings and Wheel
./build.sh ${BUILDARGS} --enable_pybind --build_wheel
sudo pip3 install build/Linux/Release/dist/*-linux_x86_64.whl

#or just download wheel from repo, unzip and install
