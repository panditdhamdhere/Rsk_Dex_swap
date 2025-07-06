# Deployment Guide

This guide explains how to deploy the RskDex contracts to different networks.

## Prerequisites

1. **Foundry**: Make sure you have Foundry installed
2. **Private Key**: Set your deployment private key as an environment variable
3. **RPC URL**: Set the RPC URL for your target network

## Environment Setup

Set your environment variables:

```bash
export PRIVATE_KEY=your_private_key_here
export RPC_URL=your_rpc_url_here
```

## Deployment Options

### Option 1: Using the Shell Script (Recommended)

```bash
# Make the script executable
chmod +x script/deploy.sh

# Deploy to local network
./script/deploy.sh local

# Deploy to a specific network
./script/deploy.sh sepolia
```

### Option 2: Using Foundry Commands Directly

```bash
# Deploy to local network
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

# Deploy to testnet with verification
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### Option 3: Deploy to Local Anvil Network

```bash
# Start local anvil instance
anvil

# In another terminal, deploy to local network
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

## What Gets Deployed

The deployment script will deploy:

1. **RskDex**: The main DEX contract
2. **MockERC20 TokenA**: A mock ERC20 token for testing
3. **MockERC20 TokenB**: Another mock ERC20 token for testing
4. **Pool**: A liquidity pool between TokenA and TokenB
5. **Initial Liquidity**: 1M tokens of each type are added to the pool

## Deployment Output

After successful deployment, you'll see output similar to:

```
RskDex deployed at: 0x...
TokenA deployed at: 0x...
TokenB deployed at: 0x...
Pool created with ID: ...
Initial liquidity added:
  TokenA amount: 1000000000000000000000000
  TokenB amount: 1000000000000000000000000
  Liquidity tokens: ...

=== DEPLOYMENT SUMMARY ===
Deployer: 0x...
RskDex: 0x...
TokenA: 0x...
TokenB: 0x...
Pool ID: ...
Initial reserves:
  TokenA reserve: 1000000000000000000000000
  TokenB reserve: 1000000000000000000000000
========================
```

## Network-Specific Configuration

### Local Development (Anvil)
```bash
export RPC_URL=http://localhost:8545
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Sepolia Testnet
```bash
export RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
export PRIVATE_KEY=your_private_key_here
```

### Mainnet
```bash
export RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
export PRIVATE_KEY=your_private_key_here
```

## Post-Deployment

After deployment, you can:

1. **Verify contracts** on Etherscan (if deployed to a public network)
2. **Test the DEX** by performing swaps and adding/removing liquidity
3. **Interact with the contracts** using the provided addresses

## Troubleshooting

### Common Issues

1. **Insufficient funds**: Make sure your deployment account has enough ETH for gas
2. **Invalid private key**: Ensure your private key is correctly formatted (without 0x prefix)
3. **RPC errors**: Check your RPC URL and network connectivity
4. **Compilation errors**: Run `forge build` to ensure contracts compile successfully

### Getting Help

If you encounter issues:
1. Check the Foundry documentation
2. Verify your environment variables are set correctly
3. Ensure you have sufficient funds in your deployment account 