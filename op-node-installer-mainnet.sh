#!/bin/bash

# Created with love by @iwantanode for Optimism

# Install all the utils
sudo apt update
sudo apt install -y git curl make jq zstd

# Install Go
wget https://go.dev/dl/go1.20.linux-amd64.tar.gz
tar xvzf go1.20.linux-amd64.tar.gz
sudo cp go/bin/go /usr/bin/go
sudo mv go /usr/lib
echo export GOROOT=/usr/lib/go >> ~/.bashrc

# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install node
nvm alias default v18.17.1
nvm install 18.17.1
nvm use 18.17.1

# Install pnpm
sudo apt install npm
npm install -g pnpm

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
. ~/.bashrc
source /root/.bashrc
source /root/.bashrc;
source /root/.bashrc;
foundryup


# Build the OP node
git clone https://github.com/ethereum-optimism/optimism.git
cd optimism
pnpm install
make op-node
pnpm build

# Build op-geth
git clone https://github.com/ethereum-optimism/op-geth.git
cd op-geth    
make geth

# Download datadir for op-geth
echo "Downloading data dir..."
mkdir datadir
cd datadir
curl -O https://datadirs.optimism.io/mainnet-bedrock.tar.zst


checksum=$(sha256sum mainnet-bedrock.tar.zst | awk '{print $1}')
expected_checksum="ec4baf47e309a14ffbd586dc85376833de640c0f2a8d7355cb8a9e64c38bfcd1"
if [ "$checksum" == "$expected_checksum" ]; then
    echo "Checksum matches!"
else
    echo "Checksum does NOT match!"
fi
tar xvf mainnet-bedrock.tar.zst

# Create a shared secret between op-geth and op-node
cd ..
cd ..
openssl rand -hex 32 > jwt.txt
cp jwt.txt ../optimism/op-node

cd op-geth
SEQUENCER_URL=https://mainnet-sequencer.optimism.io/

./build/bin/geth \
  --datadir=./datadir \
  --http \
  --http.port=8545 \
  --http.addr=0.0.0.0 \
  --authrpc.addr=localhost \
  --authrpc.jwtsecret=./jwt.txt \
  --verbosity=3 \
  --rollup.sequencerhttp=$SEQUENCER_URL \
  --nodiscover \
  --syncmode=full \
  --maxpeers=0



# op-node
cd ..
cd op-node
echo "To run a node you ll need to get a rpc url from alchemy/infura/quicknode"
echo "Create an account on https://dashboard.alchemy.com/apps"
echo "go to https://dashboard.alchemy.com/apps"
echo "Create new app -> chose Ethereum Testnet Sepolia"
read -p "Copy the link under HTTPS and paste it here:" L1_RPC
read -p "please write the provider here(alchemy, quicknode, infura, parity, nethermind, debug_geth, erigon, basic, any)" L1KIND

L1URL=$L1_RPC
L1KIND=$L1KIND
NET=mainnet
./bin/op-node \
    --l1=$L1URL  \
    --l1.rpckind=$L1KIND \
    --l2=http://localhost:8551 \
    --l2.jwt-secret=./jwt.txt \
    --network=$NET \
    --rpc.addr=0.0.0.0 \
    --rpc.port=8547