const express = require('express');
const cors = require('cors');
const { ethers } = require('ethers');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

// Contract ABIs (simplified - in production, import from compiled artifacts)
const ERC20_ABI = [
    "function balanceOf(address owner) view returns (uint256)",
    "function decimals() view returns (uint8)",
    "function symbol() view returns (string)",
    "function name() view returns (string)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function approve(address spender, uint256 amount) returns (bool)",
    "function transfer(address to, uint256 amount) returns (bool)"
];

const SWAP_ABI = [
    "function swapAForB(uint256 amountIn, uint256 minAmountOut) returns (uint256)",
    "function swapBForA(uint256 amountIn, uint256 minAmountOut) returns (uint256)",
    "function getAmountOut(address tokenIn, uint256 amountIn) view returns (uint256)",
    "function getReserves() view returns (uint256, uint256)",
    "function getExchangeRate() view returns (uint256)",
    "function tokenA() view returns (address)",
    "function tokenB() view returns (address)",
    "function addLiquidity(uint256 amountA, uint256 amountB)",
    "function reserveA() view returns (uint256)",
    "function reserveB() view returns (uint256)"
];

// Initialize provider (use your RPC URL)
const RPC_URL = process.env.RPC_URL || 'http://localhost:8545'; // Default to local node
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Helper function to get contract instance
function getContract(address, abi) {
    return new ethers.Contract(address, abi, provider);
}

// API Routes

// Get token information
app.get('/api/token/:address', async (req, res) => {
    try {
        const tokenAddress = req.params.address;
        const tokenContract = getContract(tokenAddress, ERC20_ABI);
        
        const [name, symbol, decimals] = await Promise.all([
            tokenContract.name(),
            tokenContract.symbol(),
            tokenContract.decimals()
        ]);
        
        res.json({ name, symbol, decimals: decimals.toString() });
    } catch (error) {
        console.error('Error fetching token info:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get token balance
app.get('/api/balance/:tokenAddress/:userAddress', async (req, res) => {
    try {
        const { tokenAddress, userAddress } = req.params;
        const tokenContract = getContract(tokenAddress, ERC20_ABI);
        
        const balance = await tokenContract.balanceOf(userAddress);
        const decimals = await tokenContract.decimals();
        
        res.json({ 
            balance: balance.toString(),
            formatted: ethers.formatUnits(balance, decimals)
        });
    } catch (error) {
        console.error('Error fetching balance:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get swap contract info
app.get('/api/swap/:swapAddress', async (req, res) => {
    try {
        const swapAddress = req.params.swapAddress;
        const swapContract = getContract(swapAddress, SWAP_ABI);
        
        const [tokenA, tokenB, reserveA, reserveB, exchangeRate] = await Promise.all([
            swapContract.tokenA(),
            swapContract.tokenB(),
            swapContract.reserveA(),
            swapContract.reserveB(),
            swapContract.getExchangeRate()
        ]);
        
        res.json({
            tokenA,
            tokenB,
            reserveA: reserveA.toString(),
            reserveB: reserveB.toString(),
            exchangeRate: exchangeRate.toString()
        });
    } catch (error) {
        console.error('Error fetching swap info:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get swap quote
app.post('/api/swap/quote', async (req, res) => {
    try {
        const { swapAddress, tokenIn, amountIn } = req.body;
        
        if (!swapAddress || !tokenIn || !amountIn) {
            return res.status(400).json({ error: 'Missing required parameters' });
        }
        
        const swapContract = getContract(swapAddress, SWAP_ABI);
        const amountOut = await swapContract.getAmountOut(tokenIn, amountIn);
        
        res.json({ amountOut: amountOut.toString() });
    } catch (error) {
        console.error('Error getting quote:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get allowance
app.get('/api/allowance/:tokenAddress/:owner/:spender', async (req, res) => {
    try {
        const { tokenAddress, owner, spender } = req.params;
        const tokenContract = getContract(tokenAddress, ERC20_ABI);
        
        const allowance = await tokenContract.allowance(owner, spender);
        const decimals = await tokenContract.decimals();
        
        res.json({
            allowance: allowance.toString(),
            formatted: ethers.formatUnits(allowance, decimals)
        });
    } catch (error) {
        console.error('Error fetching allowance:', error);
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve frontend
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`RPC URL: ${RPC_URL}`);
});
