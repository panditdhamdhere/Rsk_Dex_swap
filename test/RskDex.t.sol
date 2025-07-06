// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {RskDex} from "../src/RskDex.sol";
import {MockERC20} from "../src/mock/MockERC20.sol";

contract RskDexTest is Test {
    RskDex public dex;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    bytes32 public poolId;

    function setUp() public {
        // Deploy contracts
        dex = new RskDex();
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        // Create pool
        poolId = dex.createPool(address(tokenA), address(tokenB));

        // Mint tokens to users
        tokenA.mint(user1, 1000000 * 10 ** 18);
        tokenB.mint(user1, 1000000 * 10 ** 18);
        tokenA.mint(user2, 1000000 * 10 ** 18);
        tokenB.mint(user2, 1000000 * 10 ** 18);
    }

    function testCreatePool() public {
        bytes32 expectedPoolId = dex.getPoolId(
            address(tokenA),
            address(tokenB)
        );
        assertEq(poolId, expectedPoolId);
        assertTrue(dex.poolExists(poolId));
    }

    function testCreatePoolWithIdenticalTokens() public {
        vm.expectRevert("Identical tokens");
        dex.createPool(address(tokenA), address(tokenA));
    }

    function testCreatePoolWithZeroAddress() public {
        vm.expectRevert("Zero address");
        dex.createPool(address(0), address(tokenA));
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = dex
            .addLiquidity(poolId, amountA, amountB, 0, 0, user1);

        assertEq(actualAmountA, amountA);
        assertEq(actualAmountB, amountB);
        assertGt(liquidity, 0);

        (uint256 reserveA, uint256 reserveB) = dex.getReserves(poolId);
        assertEq(reserveA, amountA);
        assertEq(reserveB, amountB);

        vm.stopPrank();
    }

    function testAddLiquidityWithRatio() public {
        // First add initial liquidity
        vm.startPrank(user1);

        uint256 initialAmountA = 1000 * 10 ** 18;
        uint256 initialAmountB = 2000 * 10 ** 18;

        tokenA.approve(address(dex), initialAmountA);
        tokenB.approve(address(dex), initialAmountB);

        dex.addLiquidity(poolId, initialAmountA, initialAmountB, 0, 0, user1);

        vm.stopPrank();

        // Now add liquidity with different ratio
        vm.startPrank(user2);

        uint256 amountA = 500 * 10 ** 18;
        uint256 amountB = 2000 * 10 ** 18; // This should be adjusted to maintain ratio

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        (uint256 actualAmountA, uint256 actualAmountB, ) = dex.addLiquidity(
            poolId,
            amountA,
            amountB,
            0,
            0,
            user2
        );

        assertEq(actualAmountA, amountA);
        assertEq(actualAmountB, amountA * 2); // Should maintain 1:2 ratio

        vm.stopPrank();
    }

    function testSwap() public {
        // Add initial liquidity
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 1000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        dex.addLiquidity(poolId, amountA, amountB, 0, 0, user1);

        vm.stopPrank();

        // Perform swap
        vm.startPrank(user2);

        uint256 swapAmount = 100 * 10 ** 18;
        uint256 expectedOut = dex.getAmountOut(swapAmount, amountA, amountB);

        tokenA.approve(address(dex), swapAmount);

        uint256 balanceBBefore = tokenB.balanceOf(user2);
        uint256 amountOut = dex.swap(
            poolId,
            address(tokenA),
            swapAmount,
            0,
            user2
        );
        uint256 balanceBAfter = tokenB.balanceOf(user2);

        assertEq(amountOut, expectedOut);
        assertEq(balanceBAfter - balanceBBefore, amountOut);

        vm.stopPrank();
    }

    function testGetAmountOut() public {
        uint256 amountIn = 100 * 10 ** 18;
        uint256 reserveIn = 1000 * 10 ** 18;
        uint256 reserveOut = 1000 * 10 ** 18;

        uint256 amountOut = dex.getAmountOut(amountIn, reserveIn, reserveOut);

        // With 0.3% fee, expected output should be less than input
        assertLt(amountOut, amountIn);
        assertGt(amountOut, 0);
    }

    function testGetAmountIn() public {
        uint256 amountOut = 90 * 10 ** 18;
        uint256 reserveIn = 1000 * 10 ** 18;
        uint256 reserveOut = 1000 * 10 ** 18;

        uint256 amountIn = dex.getAmountIn(amountOut, reserveIn, reserveOut);

        // With 0.3% fee, required input should be more than output
        assertGt(amountIn, amountOut);
    }

    function testRemoveLiquidity() public {
        // Add liquidity first
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 1000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        (, , uint256 liquidity) = dex.addLiquidity(
            poolId,
            amountA,
            amountB,
            0,
            0,
            user1
        );

        // Remove half the liquidity
        uint256 liquidityToRemove = liquidity / 2;

        uint256 balanceABefore = tokenA.balanceOf(user1);
        uint256 balanceBBefore = tokenB.balanceOf(user1);

        (uint256 amountAOut, uint256 amountBOut) = dex.removeLiquidity(
            poolId,
            liquidityToRemove,
            0,
            0,
            user1
        );

        uint256 balanceAAfter = tokenA.balanceOf(user1);
        uint256 balanceBAfter = tokenB.balanceOf(user1);

        assertEq(balanceAAfter - balanceABefore, amountAOut);
        assertEq(balanceBAfter - balanceBBefore, amountBOut);

        // Should get approximately half of the tokens back
        assertApproxEqRel(amountAOut, amountA / 2, 0.01e18); // 1% tolerance
        assertApproxEqRel(amountBOut, amountB / 2, 0.01e18); // 1% tolerance

        vm.stopPrank();
    }

    function testSwapInsufficientLiquidity() public {
        vm.startPrank(user1);

        uint256 swapAmount = 100 * 10 ** 18;
        tokenA.approve(address(dex), swapAmount);

        vm.expectRevert("Insufficient liquidity");
        dex.swap(poolId, address(tokenA), swapAmount, 0, user1);

        vm.stopPrank();
    }

    function testSwapInsufficientOutput() public {
        // Add liquidity first
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 1000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        dex.addLiquidity(poolId, amountA, amountB, 0, 0, user1);

        // Try to swap with unrealistic minimum output
        uint256 swapAmount = 100 * 10 ** 18;
        uint256 unrealisticMinOut = 200 * 10 ** 18; // More than possible

        tokenA.approve(address(dex), swapAmount);

        vm.expectRevert("Insufficient output amount");
        dex.swap(poolId, address(tokenA), swapAmount, unrealisticMinOut, user1);

        vm.stopPrank();
    }

    function testLiquiditySlippage() public {
        // Add initial liquidity
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 1000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        dex.addLiquidity(poolId, amountA, amountB, 0, 0, user1);

        vm.stopPrank();

        // Try to add liquidity with slippage protection
        vm.startPrank(user2);

        uint256 amountA2 = 500 * 10 ** 18;
        uint256 amountB2 = 600 * 10 ** 18; // Slightly off ratio
        uint256 minAmountB = 500 * 10 ** 18; // Minimum B amount expected

        tokenA.approve(address(dex), amountA2);
        tokenB.approve(address(dex), amountB2);

        (uint256 actualAmountA, uint256 actualAmountB, ) = dex.addLiquidity(
            poolId,
            amountA2,
            amountB2,
            0,
            minAmountB,
            user2
        );

        assertEq(actualAmountA, amountA2);
        assertEq(actualAmountB, amountA2); // Should be equal due to 1:1 ratio
        assertGe(actualAmountB, minAmountB);

        vm.stopPrank();
    }

    function testFeeCalculation() public {
        // Add liquidity
        vm.startPrank(user1);

        uint256 amountA = 1000 * 10 ** 18;
        uint256 amountB = 1000 * 10 ** 18;

        tokenA.approve(address(dex), amountA);
        tokenB.approve(address(dex), amountB);

        dex.addLiquidity(poolId, amountA, amountB, 0, 0, user1);

        vm.stopPrank();

        // Calculate expected output with fee
        uint256 swapAmount = 100 * 10 ** 18;
        uint256 expectedOutWithoutFee = (swapAmount * amountB) /
            (amountA + swapAmount);
        uint256 expectedOutWithFee = dex.getAmountOut(
            swapAmount,
            amountA,
            amountB
        );

        // Output with fee should be less than without fee
        assertLt(expectedOutWithFee, expectedOutWithoutFee);

        // Fee should be approximately 0.3%
        uint256 feeAmount = expectedOutWithoutFee - expectedOutWithFee;
        uint256 expectedFee = (expectedOutWithoutFee * 3) / 1000;

        assertApproxEqRel(feeAmount, expectedFee, 0.1e18); // 10% tolerance for rounding
    }
}
