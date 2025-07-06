// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {RskDex} from "../src/RskDex.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

contract DeployScript is Script {
    function run() public {
        // Deploy the DEX contract
        RskDex dex = new RskDex();
        console.log("RskDex deployed at:", address(dex));

        // Deploy mock tokens
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));

        // Create a pool
        bytes32 poolId = dex.createPool(address(tokenA), address(tokenB));
        console.log("Pool created with ID:", uint256(poolId));

        // Add initial liquidity
        uint256 initialAmountA = 1000000 * 10 ** 18; // 1M tokens
        uint256 initialAmountB = 1000000 * 10 ** 18; // 1M tokens

        // Approve tokens for DEX
        tokenA.approve(address(dex), initialAmountA);
        tokenB.approve(address(dex), initialAmountB);

        // Add liquidity
        (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = dex.addLiquidity(
            poolId,
            initialAmountA,
            initialAmountB,
            0, // amountAMin
            0, // amountBMin
            msg.sender
        );

        console.log("Initial liquidity added:");
        console.log("  TokenA amount:", actualAmountA);
        console.log("  TokenB amount:", actualAmountB);
        console.log("  Liquidity tokens:", liquidity);

        // Log deployment summary
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Deployer:", msg.sender);
        console.log("RskDex:", address(dex));
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("Pool ID:", uint256(poolId));
        
        // Get pool reserves
        (uint256 reserveA, uint256 reserveB) = dex.getReserves(poolId);
        console.log("Initial reserves:");
        console.log("  TokenA reserve:", reserveA);
        console.log("  TokenB reserve:", reserveB);
        console.log("========================\n");
    }

    // Function to deploy only the DEX (without mock tokens)
    function deployDexOnly() public {
        RskDex dex = new RskDex();
        console.log("RskDex deployed at:", address(dex));
    }

    // Function to deploy only mock tokens
    function deployMockTokens() public {
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
    }

    // Function to create pool with existing tokens
    function createPool(address dexAddress, address tokenA, address tokenB) public {
        RskDex dex = RskDex(dexAddress);
        bytes32 poolId = dex.createPool(tokenA, tokenB);
        console.log("Pool created with ID:", vm.toString(poolId));
    }
} 