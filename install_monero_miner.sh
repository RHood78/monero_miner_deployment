#!/bin/sh
# Monero Miner Deployment
# By Rahim Khoja (rahimk@khojacorp.com)

# Default Wallet Address & Pool Host Values
defaultwal=42zZCLkD6VV73LX1u7fRnQ2STLXutXZMhEFp74LncVf2MnNrYD4xoXufa26zbdkttndxfWnJeZqYQVaHTYU2kohrUrhnTqG
defaulthost=vegas-backup.xmrpool.net:3333

# Get Wallet Address
finish="-1"
while [ "$finish" = '-1' ]
  do
    finish="1"
    read -p "Enter Monero Wallet Address [$defaultwal]: " WALLET
    WALLET=${WALLET:-$defaultwal}
    echo
    read -p "Wallet Address is: $WALLET [y/n]? " answer

    if [ "$answer" = '' ];
    then
      answer=""
    else
      case $answer in
        y | Y | yes | YES ) answer="y";;
        n | N | no | NO ) answer="n"; finish="-1";;
        *) finish="-1";
           echo -n 'Invalid Response\n';
       esac
    fi
done
echo

# Get Pool Address
finish="-1"
while [ "$finish" = '-1' ]
  do
    finish="1"
    read -p "Enter Monero Pool Host [$defaulthost]: " MINEHOST
    MINEHOST=${MINEHOST:-$defaulthost}
    echo
    read -p "Monero Pool is: $MINEHOST [y/n]? " answer

    if [ "$answer" = '' ];
    then
      answer=""
    else
      case $answer in
        y | Y | yes | YES ) answer="y";;
        n | N | no | NO ) answer="n"; finish="-1";;
        *) finish="-1";
           echo -n 'Invalid Response\n';
       esac
    fi
done

# Confirm Install
echo "Monero Wallet Address: $WALLET"
echo "Monero Pool Host: $MINEHOST"

read -p "Are you sure you want to continue? (y/n)?" CONT
if [  "$CONT" != "y" ]; then
  echo "Exiting!"
  exit 1;
fi
echo
echo "Installing Monero Miner"

# Update & Upgrade Apt
sudo apt-get -y update && sudo apt-get -y upgrade

# Install Required Packages via APT
sudo apt-get -y install git wget build-essential autotools-dev libcurl3 automake autoconf pkg-config libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev make g++
sudo apt -y install libmicrohttpd-dev cmake libhwloc-dev

#Download Latest Source of XMR-STAK miner
git clone https://github.com/fireice-uk/xmr-stak.git

sudo nano ~/monero_miner_deployment/xmr-stak/xmrstak/donate-level.hpp

#Make build Directory
mkdir xmr-stak/build

# Change to Miner Directory
cd xmr-stak/build

# Compile Miner
cmake .. -DCUDA_ENABLE=OFF -DOpenCL_ENABLE=OFF
## add -DCUDA_ENABLE=OFF or -DOpenCL_ENABLE=OFF
## or -DOpenCL_INCLUDE_DIR=/opt/amdgpu-pro/lib/x86_64-linux-gnu
## or -DOpenCL_LIBRARY=/opt/AMDAPPSDK-3.0/lib/x86_64/sdk/libOpenCL.so -DOpenCL_INCLUDE_DIR=/opt/AMDAPPSDK-3.0/include/CL
## or -DOpenCL_LIBRARY=/opt/amdgpu-pro/lib/x86_64-linux-gnu/libOpenCL.so -DOpenCL_INCLUDE_DIR=/opt/amdgpu-pro/bin

# Install Miner
make install
## if u get error 'CL/cl.h: No such file or directory', try: sudo apt-get install opencl-headers

#copy miner for systemd use
cd ~/monero_miner_deployment/xmr-stak/build/bin
cp bin/xmr-stak /usr/local/bin/xmr-stak # so system can execute
#/usr/local/bin/xmr-stak -c ~/xmr-stak/config.txt

# Change to Monero Miner Deployment Directory
cd ~/monero_miner_deployment/

# Copy Miner Service File
#sudo /bin/bash -c "cp $(pwd -P)/monero-miner.service /lib/systemd/system/"
sudo /bin/bash -c "cp $(pwd -P)/monero-miner.service /etc/systemd/system/"

## Update Miner Systemd Service File With Wallet & Pool Information
#sudo sed -i "s/walletaddress/$WALLET/" /lib/systemd/system/monero-miner.service
#sudo sed -i "s/mineaddress/$MINEHOST/" /lib/systemd/system/monero-miner.service

# Reload Systemd Services
sudo systemctl daemon-reload

## Enable & Start the Miner
sudo systemctl start monero-miner.service
sudo systemctl status monero-miner.service #chek for errors
sudo systemctl enable monero-miner.service #enable for system startup

# Install Complete
echo "Install Complete!"
