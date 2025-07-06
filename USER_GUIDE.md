# RskDex User Guide

A comprehensive guide for interacting with the deployed RskDex contracts on Rootstock testnet.

## 🚀 Quick Start

### Contract Addresses (Rootstock Testnet)

- **RskDex**: `0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141`
- **TokenA**: `0xdaE97900D4B184c5D2012dcdB658c008966466DD`
- **TokenB**: `0x238213078DbD09f2D15F4c14c02300FA1b2A81BB`
- **Pool ID**: `67090853379251962798850964899703943124476323978611141630800005392808089842071`

### Block Explorer
- **Rootstock Testnet Explorer**: [https://explorer.testnet.rsk.co](https://explorer.testnet.rsk.co)

## 📋 Prerequisites

1. **Wallet Setup**: MetaMask or any Web3 wallet
2. **Network Configuration**: Add Rootstock testnet to your wallet
3. **Test Tokens**: Get tRBTC from the [faucet](https://faucet.testnet.rsk.co/)

### Adding Rootstock Testnet to MetaMask

1. Open MetaMask
2. Click on the network dropdown
3. Select "Add Network"
4. Add the following details:
   - **Network Name**: Rootstock Testnet
   - **RPC URL**: `https://public-node.testnet.rsk.co`
   - **Chain ID**: `31`
   - **Currency Symbol**: `tRBTC`
   - **Block Explorer URL**: `https://explorer.testnet.rsk.co`

## 🛠️ Interacting with Contracts

### Using Foundry Cast

Foundry's `cast` command allows you to interact with contracts directly from the command line.

#### 1. Check Contract State

```bash
# Get pool reserves
cast call 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 \
  "getReserves(bytes32)" \
  0x67090853379251962798850964899703943124476323978611141630800005392808089842071 \
  --rpc-url https://public-node.testnet.rsk.co

# Check if pool exists
cast call 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 \
  "poolExists(bytes32)" \
  0x67090853379251962798850964899703943124476323978611141630800005392808089842071 \
  --rpc-url https://public-node.testnet.rsk.co
```

#### 2. Token Operations

```bash
# Check token balance
cast call 0xdaE97900D4B184c5D2012dcdB658c008966466DD \
  "balanceOf(address)" \
  0xYOUR_ADDRESS \
  --rpc-url https://public-node.testnet.rsk.co

# Approve tokens for DEX
cast send 0xdaE97900D4B184c5D2012dcdB658c008966466DD \
  "approve(address,uint256)" \
  0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 \
  1000000000000000000000000 \
  --private-key YOUR_PRIVATE_KEY \
  --rpc-url https://public-node.testnet.rsk.co
```

#### 3. DEX Operations

```bash
# Add liquidity
cast send 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 \
  "addLiquidity(bytes32,uint256,uint256,uint256,uint256,address)" \
  0x67090853379251962798850964899703943124476323978611141630800005392808089842071 \
  1000000000000000000000 \
  1000000000000000000000 \
  0 \
  0 \
  0xYOUR_ADDRESS \
  --private-key YOUR_PRIVATE_KEY \
  --rpc-url https://public-node.testnet.rsk.co

# Swap tokens
cast send 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141 \
  "swap(bytes32,address,uint256,uint256,address)" \
  0x67090853379251962798850964899703943124476323978611141630800005392808089842071 \
  0xdaE97900D4B184c5D2012dcdB658c008966466DD \
  100000000000000000000 \
  0 \
  0xYOUR_ADDRESS \
  --private-key YOUR_PRIVATE_KEY \
  --rpc-url https://public-node.testnet.rsk.co
```

### Using Web3.js/ethers.js

Here's a JavaScript example for interacting with the contracts:

```javascript
const { ethers } = require('ethers');

// Connect to Rootstock testnet
const provider = new ethers.providers.JsonRpcProvider('https://public-node.testnet.rsk.co');

// Contract ABIs (simplified)
const DEX_ABI = [
  'function addLiquidity(bytes32 poolId, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)',
  'function swap(bytes32 poolId, address tokenIn, uint256 amountIn, uint256 amountOutMin, address to) external returns (uint256 amountOut)',
  'function getReserves(bytes32 poolId) external view returns (uint256 reserveA, uint256 reserveB)',
  'function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut)'
];

const ERC20_ABI = [
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function balanceOf(address account) external view returns (uint256)',
  'function transfer(address to, uint256 amount) external returns (bool)'
];

// Contract addresses
const DEX_ADDRESS = '0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141';
const TOKENA_ADDRESS = '0xdaE97900D4B184c5D2012dcdB658c008966466DD';
const TOKENB_ADDRESS = '0x238213078DbD09f2D15F4c14c02300FA1b2A81BB';
const POOL_ID = '0x67090853379251962798850964899703943124476323978611141630800005392808089842071';

// Initialize contracts
const dex = new ethers.Contract(DEX_ADDRESS, DEX_ABI, provider);
const tokenA = new ethers.Contract(TOKENA_ADDRESS, ERC20_ABI, provider);
const tokenB = new ethers.Contract(TOKENB_ADDRESS, ERC20_ABI, provider);

// Example functions
async function addLiquidity(privateKey, amountA, amountB) {
  const wallet = new ethers.Wallet(privateKey, provider);
  const dexWithSigner = dex.connect(wallet);
  const tokenAWithSigner = tokenA.connect(wallet);
  const tokenBWithSigner = tokenB.connect(wallet);

  // Approve tokens
  await tokenAWithSigner.approve(DEX_ADDRESS, amountA);
  await tokenBWithSigner.approve(DEX_ADDRESS, amountB);

  // Add liquidity
  const tx = await dexWithSigner.addLiquidity(
    POOL_ID,
    amountA,
    amountB,
    0, // amountAMin
    0, // amountBMin
    wallet.address
  );

  const receipt = await tx.wait();
  console.log('Liquidity added:', receipt);
}

async function swapTokens(privateKey, tokenInAddress, amountIn) {
  const wallet = new ethers.Wallet(privateKey, provider);
  const dexWithSigner = dex.connect(wallet);
  const tokenIn = new ethers.Contract(tokenInAddress, ERC20_ABI, wallet);

  // Approve token for swap
  await tokenIn.approve(DEX_ADDRESS, amountIn);

  // Execute swap
  const tx = await dexWithSigner.swap(
    POOL_ID,
    tokenInAddress,
    amountIn,
    0, // amountOutMin
    wallet.address
  );

  const receipt = await tx.wait();
  console.log('Swap completed:', receipt);
}

async function getPoolInfo() {
  const [reserveA, reserveB] = await dex.getReserves(POOL_ID);
  console.log('Pool reserves:');
  console.log('TokenA:', ethers.utils.formatEther(reserveA));
  console.log('TokenB:', ethers.utils.formatEther(reserveB));
}
```

### Using Remix IDE

1. **Open Remix**: Go to [remix.ethereum.org](https://remix.ethereum.org)
2. **Connect to Rootstock**: In the Deploy tab, select "Injected Provider - MetaMask"
3. **Load Contract**: Copy the RskDex.sol contract code
4. **Deploy or Connect**: Either deploy a new instance or connect to the existing one
5. **Interact**: Use the contract interface to call functions

## 📊 Understanding Pool Mechanics

### Constant Product Formula

The DEX uses the constant product formula: `x * y = k`

- **x**: Reserve of token A
- **y**: Reserve of token B
- **k**: Constant product

### Price Impact

The price impact increases with trade size:

```
Price Impact = (Amount In / Reserve In) * 100%
```

### Slippage Protection

Always set minimum amounts to protect against slippage:

```javascript
// Calculate expected output
const expectedOut = await dex.getAmountOut(amountIn, reserveIn, reserveOut);

// Set minimum output (e.g., 1% slippage tolerance)
const minOut = expectedOut.mul(99).div(100);
```

## 🔍 Monitoring Transactions

### Block Explorer

Monitor your transactions on the [Rootstock Testnet Explorer](https://explorer.testnet.rsk.co):

1. Search for your transaction hash
2. View transaction details, gas used, and status
3. Check contract interactions and events

### Event Logs

The DEX emits events for all major operations:

- `LiquidityAdded`: When liquidity is added to a pool
- `LiquidityRemoved`: When liquidity is removed from a pool
- `Swap`: When tokens are swapped

## ⚠️ Common Issues and Solutions

### 1. Insufficient Gas

**Problem**: Transaction fails due to insufficient gas
**Solution**: Increase gas limit or get more tRBTC from faucet

### 2. Slippage Protection

**Problem**: Transaction reverts due to slippage
**Solution**: Increase slippage tolerance or reduce trade size

### 3. Token Approval

**Problem**: Transaction fails due to insufficient allowance
**Solution**: Approve tokens before trading

```javascript
// Check allowance
const allowance = await token.allowance(userAddress, dexAddress);
if (allowance.lt(amount)) {
  await token.approve(dexAddress, amount);
}
```

### 4. Network Issues

**Problem**: RPC connection problems
**Solution**: Use alternative RPC endpoints or check network status

## 🧪 Testing Your Interactions

### Test Scenarios

1. **Small Swap**: Test with small amounts first
2. **Liquidity Addition**: Add small amounts of liquidity
3. **Price Impact**: Test different trade sizes to understand price impact
4. **Slippage**: Test with different slippage settings

### Gas Estimation

Always estimate gas before transactions:

```javascript
const gasEstimate = await contract.estimateGas.functionName(params);
console.log('Estimated gas:', gasEstimate.toString());
```

## 📈 Advanced Usage

### Price Calculations

```javascript
// Calculate optimal swap amount
async function calculateOptimalSwap(amountIn, reserveIn, reserveOut) {
  const amountOut = await dex.getAmountOut(amountIn, reserveIn, reserveOut);
  const priceImpact = amountIn.mul(10000).div(reserveIn);
  
  return {
    amountOut,
    priceImpact: priceImpact.toNumber() / 100
  };
}
```

### Liquidity Management

```javascript
// Calculate optimal liquidity amounts
function calculateOptimalLiquidity(amountA, reserveA, reserveB) {
  if (reserveA.eq(0) && reserveB.eq(0)) {
    return { amountA, amountB };
  }
  
  const amountBOptimal = amountA.mul(reserveB).div(reserveA);
  return { amountA, amountB: amountBOptimal };
}
```

## 🔗 Useful Links

- [Rootstock Documentation](https://developers.rsk.co/)
- [Foundry Documentation](https://book.getfoundry.sh/)
- [Ethereum ABI Specification](https://docs.soliditylang.org/en/latest/abi-spec.html)
- [Web3.js Documentation](https://web3js.org/docs/)
- [ethers.js Documentation](https://docs.ethers.io/)

## 📞 Support

If you encounter issues:

1. Check the [troubleshooting section](#-common-issues-and-solutions)
2. Review transaction logs on the block explorer
3. Test with smaller amounts first
4. Verify network configuration

---

**Note**: This guide is for educational purposes. Always test thoroughly before using real funds. 