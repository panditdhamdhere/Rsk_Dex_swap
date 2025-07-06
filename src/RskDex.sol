// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title RSK DEX
 * @dev A simplified Uniswap V4-like DEX implementation
 * Features:
 * - Constant product formula (x * y = k)
 * - Add/Remove liquidity
 * - Token swaps
 * - Fee collection (0.3%)
 * - Price oracle functionality
 */
contract RskDex is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Events
    event LiquidityAdded(
        address indexed provider,
        uint256 tokenAAmount,
        uint256 tokenBAmount,
        uint256 liquidity
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 tokenAAmount,
        uint256 tokenBAmount,
        uint256 liquidity
    );

    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    // Pool structure
    struct Pool {
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalSupply;
        uint256 kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
        mapping(address => uint256) liquidity;
    }

    // State variables
    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => bool) public poolExists;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant FEE_NUMERATOR = 3; // 0.3%
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;

    // Price oracle
    mapping(bytes32 => uint256) public price0CumulativeLast;
    mapping(bytes32 => uint256) public price1CumulativeLast;
    mapping(bytes32 => uint32) public blockTimestampLast;

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Create a new liquidity pool
     */
    function createPool(
        address tokenA,
        address tokenB
    ) external returns (bytes32 poolId) {
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");

        // Sort tokens to ensure consistent pool ID
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        poolId = keccak256(abi.encodePacked(token0, token1));

        require(!poolExists[poolId], "Pool already exists");

        Pool storage pool = pools[poolId];
        pool.tokenA = IERC20(token0);
        pool.tokenB = IERC20(token1);
        poolExists[poolId] = true;

        return poolId;
    }

    /**
     * @dev Add liquidity to a pool
     */
    function addLiquidity(
        bytes32 poolId,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        require(poolExists[poolId], "Pool does not exist");
        Pool storage pool = pools[poolId];

        (amountA, amountB) = _addLiquidity(
            pool,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        pool.tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        pool.tokenB.safeTransferFrom(msg.sender, address(this), amountB);

        liquidity = _mint(pool, to);

        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /**
     * @dev Remove liquidity from a pool
     */
    function removeLiquidity(
        bytes32 poolId,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(poolExists[poolId], "Pool does not exist");
        Pool storage pool = pools[poolId];

        (amountA, amountB) = _burn(pool, liquidity, to);

        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");

        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }

    /**
     * @dev Swap tokens
     */
    function swap(
        bytes32 poolId,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external nonReentrant returns (uint256 amountOut) {
        require(poolExists[poolId], "Pool does not exist");
        Pool storage pool = pools[poolId];

        require(
            tokenIn == address(pool.tokenA) || tokenIn == address(pool.tokenB),
            "Invalid token"
        );

        bool isTokenA = tokenIn == address(pool.tokenA);
        (uint256 reserveIn, uint256 reserveOut) = isTokenA
            ? (pool.reserveA, pool.reserveB)
            : (pool.reserveB, pool.reserveA);

        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output amount");

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        if (isTokenA) {
            pool.reserveA += amountIn;
            pool.reserveB -= amountOut;
            pool.tokenB.safeTransfer(to, amountOut);
        } else {
            pool.reserveB += amountIn;
            pool.reserveA -= amountOut;
            pool.tokenA.safeTransfer(to, amountOut);
        }

        _update(pool, poolId);

        emit Swap(
            msg.sender,
            tokenIn,
            isTokenA ? address(pool.tokenB) : address(pool.tokenA),
            amountIn,
            amountOut
        );
    }

    /**
     * @dev Get amount out for a given input
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Get amount in for a given output
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        require(amountOut > 0, "Insufficient output amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) *
            (FEE_DENOMINATOR - FEE_NUMERATOR);
        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @dev Get pool reserves
     */
    function getReserves(
        bytes32 poolId
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        Pool storage pool = pools[poolId];
        return (pool.reserveA, pool.reserveB);
    }

    /**
     * @dev Get user's liquidity in a pool
     */
    function getUserLiquidity(
        bytes32 poolId,
        address user
    ) external view returns (uint256) {
        return pools[poolId].liquidity[user];
    }

    /**
     * @dev Get pool ID for token pair
     */
    function getPoolId(
        address tokenA,
        address tokenB
    ) external pure returns (bytes32) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // Internal functions
    function _addLiquidity(
        Pool storage pool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (pool.reserveA == 0 && pool.reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = (amountADesired * pool.reserveB) /
                pool.reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * pool.reserveA) /
                    pool.reserveB;
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "Insufficient A amount");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _mint(
        Pool storage pool,
        address to
    ) internal returns (uint256 liquidity) {
        uint256 balanceA = pool.tokenA.balanceOf(address(this));
        uint256 balanceB = pool.tokenB.balanceOf(address(this));
        uint256 amountA = balanceA - pool.reserveA;
        uint256 amountB = balanceB - pool.reserveB;

        if (pool.totalSupply == 0) {
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            pool.totalSupply = MINIMUM_LIQUIDITY; // Lock minimum liquidity
        } else {
            liquidity = Math.min(
                (amountA * pool.totalSupply) / pool.reserveA,
                (amountB * pool.totalSupply) / pool.reserveB
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");

        pool.liquidity[to] += liquidity;
        pool.totalSupply += liquidity;

        pool.reserveA = balanceA;
        pool.reserveB = balanceB;
    }

    function _burn(
        Pool storage pool,
        uint256 liquidity,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        require(
            pool.liquidity[msg.sender] >= liquidity,
            "Insufficient liquidity"
        );

        uint256 balanceA = pool.tokenA.balanceOf(address(this));
        uint256 balanceB = pool.tokenB.balanceOf(address(this));

        amountA = (liquidity * balanceA) / pool.totalSupply;
        amountB = (liquidity * balanceB) / pool.totalSupply;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity burned");

        pool.liquidity[msg.sender] -= liquidity;
        pool.totalSupply -= liquidity;

        pool.tokenA.safeTransfer(to, amountA);
        pool.tokenB.safeTransfer(to, amountB);

        pool.reserveA = pool.tokenA.balanceOf(address(this));
        pool.reserveB = pool.tokenB.balanceOf(address(this));
    }

    function _update(Pool storage pool, bytes32 poolId) internal {
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast[poolId];

        if (timeElapsed > 0 && pool.reserveA != 0 && pool.reserveB != 0) {
            price0CumulativeLast[poolId] +=
                uint256((pool.reserveB * 2 ** 112) / pool.reserveA) *
                timeElapsed;
            price1CumulativeLast[poolId] +=
                uint256((pool.reserveA * 2 ** 112) / pool.reserveB) *
                timeElapsed;
        }

        blockTimestampLast[poolId] = blockTimestamp;
    }
}
