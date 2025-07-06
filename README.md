# RskDex - Decentralized Exchange on Rootstock

A simplified Uniswap V4-like decentralized exchange (DEX) implementation built for the Rootstock blockchain. This project provides a complete DEX solution with liquidity pools, token swaps, and automated market making functionality.

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Smart Contracts](#smart-contracts)
- [Installation](#installation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

- **Automated Market Making (AMM)**: Constant product formula (x \* y = k)
- **Liquidity Provision**: Add and remove liquidity from pools
- **Token Swaps**: Swap tokens with automatic price discovery
- **Fee Collection**: 0.3% trading fee on all swaps
- **Price Oracle**: Built-in price oracle functionality
- **Reentrancy Protection**: Secure against reentrancy attacks
- **Ownable**: Admin controls for contract management
- **Mock Tokens**: Test tokens for development and testing

## 🏗️ Architecture

The RskDex follows a modular architecture with the following components:

```
RskDex/
├── src/
│   ├── RskDex.sol          # Main DEX contract
│   └── mock/
│       └── MockERC20.sol   # Mock ERC20 tokens for testing
├── test/
│   └── RskDex.t.sol        # Comprehensive test suite
├── script/
│   └── Deploy.s.sol        # Deployment script
└── foundry.toml            # Foundry configuration
```

### Core Components

1. **RskDex Contract**: The main DEX contract that handles:

   - Pool creation and management
   - Liquidity provision and removal
   - Token swaps with price calculation
   - Fee collection and distribution

2. **Pool Structure**: Each pool contains:
   - Two ERC20 tokens (tokenA and tokenB)
   - Reserves for both tokens
   - Total liquidity supply
   - Individual liquidity balances
   - Price oracle data

## 📜 Smart Contracts

### RskDex.sol

The main DEX contract implementing the core functionality:

```solidity
contract RskDex is Ownable, ReentrancyGuard {
    // Pool management
    function createPool(address tokenA, address tokenB) external returns (bytes32 poolId);

    // Liquidity operations
    function addLiquidity(bytes32 poolId, uint256 amountADesired, uint256 amountBDesired,
                         uint256 amountAMin, uint256 amountBMin, address to)
        external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function removeLiquidity(bytes32 poolId, uint256 liquidity, uint256 amountAMin,
                            uint256 amountBMin, address to)
        external returns (uint256 amountA, uint256 amountB);

    // Trading operations
    function swap(bytes32 poolId, address tokenIn, uint256 amountIn,
                 uint256 amountOutMin, address to) external returns (uint256 amountOut);

    // Price calculations
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external pure returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external pure returns (uint256 amountIn);
}
```

### MockERC20.sol

A simple ERC20 token implementation for testing:

```solidity
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol);
    function mint(address to, uint256 amount) external;
}
```

## 🛠️ Installation

### Prerequisites

- [Foundry](https://getfoundry.sh/) - Ethereum development toolkit
- [Git](https://git-scm.com/) - Version control
- [Node.js](https://nodejs.org/) (optional) - For additional tooling

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/panditdhamdhere/Rsk_Dex_swap
   cd dex
   ```

2. **Install dependencies**

   ```bash
   forge install
   ```

3. **Build the project**
   ```bash
   forge build
   ```

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
forge test

# Run tests with verbose output
forge test -vv

# Run tests with gas reporting
forge test --gas-report

# Run specific test
forge test --match-test testSwap
```

### Test Coverage

The test suite covers:

- ✅ Pool creation and validation
- ✅ Liquidity addition and removal
- ✅ Token swaps with price calculations
- ✅ Fee calculations and distribution
- ✅ Slippage protection
- ✅ Error handling and edge cases
- ✅ Reentrancy protection
- ✅ Access control

## 🚀 Deployment

### Prerequisites ( if you prefer .env ( not recommended ))

1. **Get tRBTC**: Visit [Rootstock Testnet Faucet](https://faucet.testnet.rsk.co/) to get test tokens
2. **Set Environment Variables**:
   ```bash
   export PRIVATE_KEY=your_private_key_here
   ```

### Deploy to Rootstock Testnet

```bash
# Deploy using Foundry
forge script script/Deploy.s.sol:DeployScript \
    --rpc-url https://public-node.testnet.rsk.co \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --legacy
```

### Network Configuration

| Network           | Chain ID | RPC URL                            | Currency |
| ----------------- | -------- | ---------------------------------- | -------- |
| Rootstock Testnet | 31       | https://public-node.testnet.rsk.co | tRBTC    |
| Rootstock Mainnet | 30       | https://public-node.rsk.co         | RBTC     |

## 📖 Usage

### Creating a Pool

```solidity
// Create a new liquidity pool
bytes32 poolId = dex.createPool(address(tokenA), address(tokenB));
```

### Adding Liquidity

```solidity
// Approve tokens first
tokenA.approve(address(dex), amountA);
tokenB.approve(address(dex), amountB);

// Add liquidity
(uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = dex.addLiquidity(
    poolId,
    amountADesired,
    amountBDesired,
    amountAMin,  // Slippage protection
    amountBMin,  // Slippage protection
    msg.sender
);
```

### Swapping Tokens

```solidity
// Calculate expected output
uint256 expectedOut = dex.getAmountOut(amountIn, reserveIn, reserveOut);

// Approve token for swap
tokenIn.approve(address(dex), amountIn);

// Execute swap
uint256 amountOut = dex.swap(
    poolId,
    address(tokenIn),
    amountIn,
    amountOutMin,  // Slippage protection
    msg.sender
);
```

### Removing Liquidity

```solidity
// Remove liquidity
(uint256 amountA, uint256 amountB) = dex.removeLiquidity(
    poolId,
    liquidityAmount,
    amountAMin,  // Slippage protection
    amountBMin,  // Slippage protection
    msg.sender
);
```

## 📚 API Reference

### Core Functions

#### Pool Management

- `createPool(address tokenA, address tokenB) → bytes32 poolId`

  - Creates a new liquidity pool for two tokens
  - Returns the unique pool identifier

- `poolExists(bytes32 poolId) → bool`

  - Checks if a pool exists

- `getPoolId(address tokenA, address tokenB) → bytes32`
  - Returns the pool ID for a token pair

#### Liquidity Operations

- `addLiquidity(bytes32 poolId, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to) → (uint256 amountA, uint256 amountB, uint256 liquidity)`

  - Adds liquidity to a pool
  - Returns actual amounts added and liquidity tokens minted

- `removeLiquidity(bytes32 poolId, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to) → (uint256 amountA, uint256 amountB)`
  - Removes liquidity from a pool
  - Returns amounts of tokens received

#### Trading Operations

- `swap(bytes32 poolId, address tokenIn, uint256 amountIn, uint256 amountOutMin, address to) → uint256 amountOut`
  - Swaps tokens in a pool
  - Returns the amount of tokens received

#### Price Calculations

- `getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) → uint256 amountOut`

  - Calculates output amount for a given input

- `getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) → uint256 amountIn`
  - Calculates input amount needed for a given output

#### View Functions

- `getReserves(bytes32 poolId) → (uint256 reserveA, uint256 reserveB)`

  - Returns current reserves for a pool

- `getUserLiquidity(bytes32 poolId, address user) → uint256`
  - Returns user's liquidity in a pool

### Events

- `LiquidityAdded(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount, uint256 liquidity)`
- `LiquidityRemoved(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount, uint256 liquidity)`
- `Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut)`

## 🔒 Security

### Security Features

- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Slippage Protection**: Minimum amount parameters prevent MEV attacks
- **Access Control**: Ownable pattern for admin functions
- **Safe Math**: Built-in overflow protection in Solidity 0.8+
- **Input Validation**: Comprehensive parameter validation

### Audit Status

⚠️ **This code has not been audited. Use at your own risk.**

### Security Considerations

1. **Private Key Management**: Never commit private keys to version control
2. **Test Thoroughly**: Always test on testnets before mainnet deployment
3. **Monitor Transactions**: Use block explorers to monitor contract interactions
4. **Emergency Procedures**: Have a plan for emergency situations

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Add tests** for new functionality
5. **Run tests**: `forge test`
6. **Commit your changes**: `git commit -m 'Add amazing feature'`
7. **Push to the branch**: `git push origin feature/amazing-feature`
8. **Open a Pull Request**

### Development Guidelines

- Follow Solidity style guide
- Write comprehensive tests
- Add documentation for new features
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for secure contract libraries
- [Foundry](https://getfoundry.sh/) for the development toolkit
- [Rootstock](https://www.rsk.co/) for the blockchain platform
- [Uniswap](https://uniswap.org/) for the AMM inspiration

---

**Disclaimer**: This code is provided "as is" without warranty of any kind. Use at your own risk.
