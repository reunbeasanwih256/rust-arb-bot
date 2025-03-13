# Solana Arbitrage Bot Documentation

## Table of Contents
1. [Installation](#1-installation)
2. [Configuration](#2-configuration)
3. [Starting the Bot](#3-starting-the-bot)
4. [Advanced Configuration](#4-advanced-configuration)
5. [Important Notes](#5-important-notes)

## 1. Installation

### 1.1 Docker Installation

```shell
# Remove any existing Docker packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove $pkg
done

# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 1.2 Download Required Binaries

```shell
# 1. Download Jupiter Swap API (version must be >= v6.0.41)

wget https://github.com/jup-ag/jupiter-swap-api/releases/download/v6.0.41/jupiter-swap-api-x86_64-unknown-linux-gnu.zip -O jupapi/jupiter-swap-api-x86_64-unknown-linux-gnu.zip

# 2. Download Bot Binary
cp /path/to/downloaded/bot ./bot
chmod +x ./bot
```

### 1.3 Troubleshooting Common Installation Issues

#### libssl Error

If you encounter the following error when running the bot:

```shell
./bot: error while loading shared libraries: libssl.so.1.1: cannot open shared object file: No such file or directory
```

Please execute the following command to solve this problem:

```shell
docker-compose run -it --rm arb-bot1 bash
./bot --encrypt
```

## 2. Configuration

### 2.1 Environment Setup

```shell
# Create and edit .env file
cp .env.example .env
nano .env  # Add your RPC_URL and YELLOWSTONE_GRPC_ENDPOINT
```

### 2.2 Encrypt Your Private Key

```shell
# Generate encrypted private key
./bot --encrypt
# Enter your private key when prompted
# Copy the encrypted output for use in config file
```

### 2.3 Configure Trading Tokens

1. Edit `config/mints-1.json` to include the tokens you want to trade
2. Default includes SOL and USDC:
   ```json
   [
     "So11111111111111111111111111111111111111112",  // SOL
     "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"  // USDC
   ]
   ```

### 2.4 Configure Bot Settings

Edit `config/config-1.toml` with your settings:
- Add your encrypted private key
- Configure trading strategies
- Set RPC URLs and other parameters

Example wallet configuration:
```toml
[wallet]
payer_private_key = "encrypted:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"  # Your encrypted key
```

## 3. Starting the Bot

```shell
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f arb-bot1

# Stop services
docker-compose down
```

## 4. Advanced Configuration

### 4.1 IP Pool Configuration

For servers with multiple IP addresses:
- Use the built-in `ippool-haproxy` service
- Configure in `ippool-haproxy/generate-config.sh`

Alternative options:
1. Deploy on a separate machine:
   ```shell
   mkdir -p ippool-haproxy
   # Copy generate-config.sh to the new machine
   docker run -d --name ippool-haproxy --network host --privileged haproxy:latest /bin/bash /path/to/generate-config.sh
   ```

2. Use third-party IP pool services:
   ```toml
   # In config-1.toml
   [jupiter]
   url = "http://external-ippool-service:port"
   ```

## 5. Important Notes

### 5.1 Profit Sharing
The arbitrage bot automatically extracts 15% of all profits generated from successful trades.

### 5.2 Monitoring Tips
- Check logs regularly
- Monitor wallet balance
- Review trading strategies periodically
- Update token configurations as needed

### 5.3 Disclaimer
**USE AT YOUR OWN RISK**

This arbitrage bot is provided "as is" without warranties. Risks include:
- Market volatility
- Technical issues
- Regulatory concerns
- Smart contract vulnerabilities
- Network congestion

The developers are not liable for any losses. Always start with small amounts for testing.




