// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @title TokenSwap
 * @dev A simple token swap contract that allows swapping one ERC20 token for another
 * 
 * Features:
 * - Swap tokens at a fixed exchange rate
 * - Liquidity management (add/remove liquidity)
 * - Price calculation based on reserves
 * 
 * Note: This is a simplified swap contract. For production, consider using established
 * protocols like Uniswap or implementing a more sophisticated AMM.
 */
contract TokenSwap {
    // Token addresses
    address public tokenA;
    address public tokenB;
    
    // Reserves for each token
    uint256 public reserveA;
    uint256 public reserveB;
    
    // Owner address
    address public owner;
    
    // Swap fee (in basis points, e.g., 30 = 0.3%)
    uint256 public swapFee = 30; // 0.3%
    
    // Events
    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    
    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );
    
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    /**
     * @dev Constructor
     * @param _tokenA Address of first token
     * @param _tokenB Address of second token
     */
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_tokenA != _tokenB, "Tokens must be different");
        
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }
    
    /**
     * @dev Add liquidity to the swap pool
     * @param amountA Amount of token A to add
     * @param amountB Amount of token B to add
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    
    /**
     * @dev Remove liquidity from the swap pool
     * @param amountA Amount of token A to remove
     * @param amountB Amount of token B to remove
     */
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");
        
        reserveA -= amountA;
        reserveB -= amountB;
        
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }
    
    /**
     * @dev Swap token A for token B
     * @param amountIn Amount of token A to swap
     * @param minAmountOut Minimum amount of token B expected (slippage protection)
     * @return amountOut Amount of token B received
     */
    function swapAForB(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calculate output amount using constant product formula: x * y = k
        uint256 amountInWithFee = amountIn * (10000 - swapFee) / 10000;
        amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
        
        require(amountOut >= minAmountOut, "Slippage too high");
        require(amountOut <= reserveB, "Insufficient reserves");
        
        // Transfer tokens
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenB).transfer(msg.sender, amountOut);
        
        // Update reserves
        reserveA += amountIn;
        reserveB -= amountOut;
        
        emit Swap(msg.sender, tokenA, tokenB, amountIn, amountOut);
        return amountOut;
    }
    
    /**
     * @dev Swap token B for token A
     * @param amountIn Amount of token B to swap
     * @param minAmountOut Minimum amount of token A expected (slippage protection)
     * @return amountOut Amount of token A received
     */
    function swapBForA(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Calculate output amount using constant product formula: x * y = k
        uint256 amountInWithFee = amountIn * (10000 - swapFee) / 10000;
        amountOut = (amountInWithFee * reserveA) / (reserveB + amountInWithFee);
        
        require(amountOut >= minAmountOut, "Slippage too high");
        require(amountOut <= reserveA, "Insufficient reserves");
        
        // Transfer tokens
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenA).transfer(msg.sender, amountOut);
        
        // Update reserves
        reserveB += amountIn;
        reserveA -= amountOut;
        
        emit Swap(msg.sender, tokenB, tokenA, amountIn, amountOut);
        return amountOut;
    }
    
    /**
     * @dev Get the expected output amount for a swap
     * @param tokenIn Address of input token
     * @param amountIn Amount of input token
     * @return amountOut Expected output amount
     */
    function getAmountOut(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        if (tokenIn == tokenA) {
            uint256 amountInWithFee = amountIn * (10000 - swapFee) / 10000;
            amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
        } else if (tokenIn == tokenB) {
            uint256 amountInWithFee = amountIn * (10000 - swapFee) / 10000;
            amountOut = (amountInWithFee * reserveA) / (reserveB + amountInWithFee);
        } else {
            revert("Invalid token");
        }
        
        return amountOut;
    }
    
    /**
     * @dev Get current reserves
     * @return _reserveA Reserve of token A
     * @return _reserveB Reserve of token B
     */
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        return (reserveA, reserveB);
    }
    
    /**
     * @dev Get current exchange rate (tokenB per tokenA)
     * @return rate Exchange rate
     */
    function getExchangeRate() external view returns (uint256 rate) {
        if (reserveA == 0) return 0;
        return (reserveB * 1e18) / reserveA;
    }
    
    /**
     * @dev Update swap fee (only owner)
     * @param _swapFee New swap fee in basis points
     */
    function setSwapFee(uint256 _swapFee) external onlyOwner {
        require(_swapFee <= 1000, "Fee cannot exceed 10%");
        swapFee = _swapFee;
    }
}
