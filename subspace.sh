#!/bin/bash
echo -e ''
curl -s https://api.testnet.run/logo.sh | bash && sleep 3
echo -e ''
GREEN="\e[32m"
NC="\e[0m"
BINARY=$(uname -m)

dependiences () {
    echo -e '\e[0;33mİnstalling Dependiences\e[0m'
    echo -e ''
    sudo apt-get update
    sudo apt install wget unzip curl -y
}

binaries () {
    mkdir $HOME/subspace-binaries && cd $HOME/subspace-binaries
    wget https://github.com/subspace/subspace/releases/download/gemini-1b-2022-jun-13/subspace-node-ubuntu-$BINARY-gemini-1b-2022-jun-13 -O subspaced
    wget https://github.com/subspace/subspace/releases/download/gemini-1b-2022-jun-13/subspace-farmer-ubuntu-$BINARY-gemini-1b-2022-jun-13 -O farmerd
    chmod +x *
    sudo mv * /usr/bin/
}

environments () {
    echo -e ${GREEN}
if [ ! $node_name ]; then
	read -p ' >>>>> Enter your node name: ' node_name
    echo 'export node_name='$node_name >> $HOME/.bash_profile
fi
sleep 3
if [ ! $wallet_address ]; then
	read -p ' >>>>> Enter your wallet address: ' wallet_address
    echo 'export wallet_address='$wallet_address >> $HOME/.bash_profile
fi
sleep 3
if [ ! $SIZE ]; then
	read -p ' >>>>> Enter Plot size
    Attention! plot size format should be in gigabytes or terabytes, For example: 100GB >> 100G or 1 Terabayt >> 1T: ' SIZE
    echo 'export SIZE='$SIZE >> $HOME/.bash_profile
fi
echo -e ${NC}
source $HOME/.bash_profile
}

daemons () {
    echo -e ""    
    echo -e '\e[0;33mCreating subspace-node daemon...\e[0m'
    echo -e ""
    sleep 2
    sudo tee <<EOF >/dev/null /etc/systemd/system/subspaced.service
[Unit]
Description=subspace-node daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/subspaced --chain gemini-1 --execution wasm --pruning 1024 --keep-blocks 1024 --validator --name $node_name
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable subspaced
echo -e ''
echo -e ${GREEN}"Starting subspace node..."${NC}
    sudo systemctl daemon-reload
    sudo systemctl restart subspaced
    sleep 1
    echo -e ""    
    echo -e '\e[0;33mCreating subspace-farmer daemon...\e[0m'
    echo -e ""
    sleep 2
    sudo tee <<EOF >/dev/null /etc/systemd/system/farmerd.service
[Unit]
Description=subspace-farmer daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/farmerd farm --reward-address $wallet_address --plot-size $SIZE
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable farmerd
sed -i 's/#Storage=auto/Storage=persistent/g' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e ''
echo -e ${GREEN}"Starting farmer..."${NC}
sudo systemctl restart farmerd
}

info () {
    echo -e ''
    echo -e ${GREEN}"======================================================"${NC}
    LOG_NODE="journalctl -u subspaced.service -fo cat"
    LOG_FARMER="journalctl -u farmerd.service -fo cat"
    source $HOME/.profile
    echo -e "Check subspace node logs: ${GREEN}$LOG_NODE${NC}"
    echo -e "Check subspace farmer logs: ${GREEN}$LOG_FARMER${NC}"
    echo -e ${GREEN}"======================================================"${NC}
}

upgrade () {
      echo -e "Upgrade process begins..."
      BINARY=$(uname -m)
      sleep 2
      cd $HOME
      echo -e ''
      echo -e ${GREEN}"Removing old binaries..."${NC}
      sudo rm -rf $HOME/subspace-binaries/* && cd $HOME/subspace-binaries
      sudo systemctl stop farmerd subspaced
      sudo rm /usr/bin/subspaced /usr/bin/farmerd
      sleep 2
      echo -e ''
      echo -e ${GREEN}"Downloading new binaries..."${NC}
      wget -q https://github.com/subspace/subspace/releases/download/gemini-1b-2022-jun-13/subspace-node-ubuntu-$BINARY-gemini-1b-2022-jun-13 -O subspaced
      wget -q https://github.com/subspace/subspace/releases/download/gemini-1b-2022-jun-13/subspace-farmer-ubuntu-$BINARY-gemini-1b-2022-jun-13 -O farmerd
      chmod +x *
      sudo mv * /usr/bin
      echo -e ''
      echo -e ${GREEN}"Starting daemons..."${NC}
      sudo systemctl restart subspaced && sleep 7
      sudo systemctl restart farmerd
      echo -e ''
      echo -e ${GREEN}"All done!"${NC}
}

PS3="What do you want?: "
select opt in Install Update Additional quit; 
do

  case $opt in
    Install)
    echo -e '\e[1;32mThe installation process begins...\e[0m'
    sleep 1
    dependiences
    binaries
    environments
    daemons
    info
    sleep 3
      break
      ;;
    Update)
    echo -e ''
    upgrade
    info
    sleep 1
      break
      ;;
    Additional)
    echo -e '\e[1;32mAdditional commands...\e[0m'
    echo -e ''
    info
    sleep 1
      ;;
    quit)
    echo -e '\e[1;32mexit...\e[0m' && sleep 1
      break
      ;;
    *) 
      echo "Invalid $REPLY"
      ;;
  esac
done
