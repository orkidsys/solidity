// Wait for ethers to be available
(function waitForEthers() {
    if (typeof ethers !== 'undefined') {
        initializeApp();
    } else {
        setTimeout(waitForEthers, 100);
    }
})();

function initializeApp() {
// Configuration
const API_URL = 'http://localhost:3001/api';
let provider = null;
let signer = null;
let userAddress = null;

// Contract addresses (will be set from config)
let swapContractAddress = '';
let tokenAAddress = '';
let tokenBAddress = '';

// Contract ABIs
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

// DOM Elements
const connectWalletBtn = document.getElementById('connectWallet');
const disconnectWalletBtn = document.getElementById('disconnectWallet');
const walletInfo = document.getElementById('walletInfo');
const walletAddress = document.getElementById('walletAddress');
const tokenASelect = document.getElementById('tokenA');
const tokenBSelect = document.getElementById('tokenB');
const amountAInput = document.getElementById('amountA');
const amountBInput = document.getElementById('amountB');
const balanceA = document.getElementById('balanceA');
const balanceB = document.getElementById('balanceB');
const swapDirectionBtn = document.getElementById('swapDirection');
const swapBtn = document.getElementById('swapBtn');
const approveBtn = document.getElementById('approveBtn');
const swapInfo = document.getElementById('swapInfo');
const statusMessage = document.getElementById('statusMessage');
const swapContractInput = document.getElementById('swapContractAddress');
const configTokenAInput = document.getElementById('configTokenA');
const configTokenBInput = document.getElementById('configTokenB');
const loadConfigBtn = document.getElementById('loadConfig');
const addLiquidityBtn = document.getElementById('addLiquidityBtn');
const liquidityCard = document.getElementById('liquidityCard');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
    checkWalletConnection();
});

function setupEventListeners() {
    connectWalletBtn.addEventListener('click', connectWallet);
    disconnectWalletBtn.addEventListener('click', disconnectWallet);
    swapDirectionBtn.addEventListener('click', swapTokens);
    amountAInput.addEventListener('input', handleAmountChange);
    tokenASelect.addEventListener('change', handleTokenChange);
    tokenBSelect.addEventListener('change', handleTokenChange);
    swapBtn.addEventListener('click', executeSwap);
    approveBtn.addEventListener('click', approveToken);
    loadConfigBtn.addEventListener('click', loadConfiguration);
    addLiquidityBtn.addEventListener('click', addLiquidity);
}

// Wallet Connection
async function connectWallet() {
    try {
        if (typeof window.ethereum !== 'undefined') {
            provider = new ethers.providers.Web3Provider(window.ethereum);
            await provider.send("eth_requestAccounts", []);
            signer = provider.getSigner();
            userAddress = await signer.getAddress();
            
            updateWalletUI();
            await loadBalances();
        } else {
            showStatus('Please install MetaMask or another Web3 wallet', 'error');
        }
    } catch (error) {
        console.error('Error connecting wallet:', error);
        showStatus('Failed to connect wallet: ' + error.message, 'error');
    }
}

function disconnectWallet() {
    provider = null;
    signer = null;
    userAddress = null;
    connectWalletBtn.style.display = 'block';
    walletInfo.style.display = 'none';
    showStatus('Wallet disconnected', 'info');
}

function updateWalletUI() {
    connectWalletBtn.style.display = 'none';
    walletInfo.style.display = 'flex';
    walletAddress.textContent = `${userAddress.slice(0, 6)}...${userAddress.slice(-4)}`;
}

async function checkWalletConnection() {
    if (typeof window.ethereum !== 'undefined') {
        provider = new ethers.providers.Web3Provider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
            signer = provider.getSigner();
            userAddress = await signer.getAddress();
            updateWalletUI();
            await loadBalances();
        }
    }
}

// Configuration
async function loadConfiguration() {
    swapContractAddress = swapContractInput.value.trim();
    tokenAAddress = configTokenAInput.value.trim();
    tokenBAddress = configTokenBInput.value.trim();
    
    if (!swapContractAddress || !tokenAAddress || !tokenBAddress) {
        showStatus('Please enter all contract addresses', 'error');
        return;
    }
    
    try {
        await loadTokenInfo(tokenAAddress, tokenASelect);
        await loadTokenInfo(tokenBAddress, tokenBSelect);
        await loadSwapInfo();
        showStatus('Configuration loaded successfully', 'success');
    } catch (error) {
        showStatus('Error loading configuration: ' + error.message, 'error');
    }
}

async function loadTokenInfo(tokenAddress, selectElement) {
    try {
        const response = await fetch(`${API_URL}/token/${tokenAddress}`);
        const data = await response.json();
        
        selectElement.innerHTML = `<option value="${tokenAddress}">${data.symbol} (${data.name})</option>`;
        selectElement.value = tokenAddress;
    } catch (error) {
        console.error('Error loading token info:', error);
    }
}

async function loadSwapInfo() {
    if (!swapContractAddress) return;
    
    try {
        const response = await fetch(`${API_URL}/swap/${swapContractAddress}`);
        const data = await response.json();
        
        // Update token addresses if not set
        if (!tokenAAddress) tokenAAddress = data.tokenA;
        if (!tokenBAddress) tokenBAddress = data.tokenB;
        
        // Update config inputs
        configTokenAInput.value = data.tokenA;
        configTokenBInput.value = data.tokenB;
        
        // Load token info
        await loadTokenInfo(data.tokenA, tokenASelect);
        await loadTokenInfo(data.tokenB, tokenBSelect);
        
        await loadBalances();
    } catch (error) {
        console.error('Error loading swap info:', error);
    }
}

// Balance Management
async function loadBalances() {
    if (!userAddress) return;
    
    if (tokenAAddress) {
        await updateBalance(tokenAAddress, balanceA);
    }
    if (tokenBAddress) {
        await updateBalance(tokenBAddress, balanceB);
    }
}

async function updateBalance(tokenAddress, element) {
    try {
        const response = await fetch(`${API_URL}/balance/${tokenAddress}/${userAddress}`);
        const data = await response.json();
        element.textContent = `Balance: ${parseFloat(data.formatted).toFixed(4)}`;
    } catch (error) {
        console.error('Error loading balance:', error);
    }
}

// Swap Logic
function swapTokens() {
    const tempAddress = tokenAAddress;
    const tempSelect = tokenASelect.value;
    const tempAmount = amountAInput.value;
    
    tokenAAddress = tokenBAddress;
    tokenBAddress = tempAddress;
    
    tokenASelect.value = tokenBSelect.value;
    tokenBSelect.value = tempSelect;
    
    amountAInput.value = amountBInput.value;
    amountBInput.value = tempAmount;
    
    handleAmountChange();
}

async function handleAmountChange() {
    const amount = amountAInput.value;
    
    if (!amount || parseFloat(amount) <= 0) {
        amountBInput.value = '';
        swapInfo.style.display = 'none';
        swapBtn.disabled = true;
        return;
    }
    
    if (!swapContractAddress || !tokenAAddress) {
        return;
    }
    
    try {
        const tokenContract = new ethers.Contract(tokenAAddress, ERC20_ABI, provider);
        const decimals = await tokenContract.decimals();
        const amountIn = ethers.utils.parseUnits(amount, decimals);
        
        const response = await fetch(`${API_URL}/swap/quote`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                swapAddress: swapContractAddress,
                tokenIn: tokenAAddress,
                amountIn: amountIn.toString()
            })
        });
        
        const data = await response.json();
        const tokenBContract = new ethers.Contract(tokenBAddress, ERC20_ABI, provider);
        const tokenBDecimals = await tokenBContract.decimals();
        const amountOut = ethers.utils.formatUnits(data.amountOut, tokenBDecimals);
        
        amountBInput.value = parseFloat(amountOut).toFixed(6);
        
        // Update swap info
        await updateSwapInfo(amount, amountOut);
        
        // Check allowance
        await checkAllowance();
        
    } catch (error) {
        console.error('Error getting quote:', error);
        showStatus('Error getting swap quote: ' + error.message, 'error');
    }
}

async function updateSwapInfo(amountIn, amountOut) {
    try {
        const swapContract = new ethers.Contract(swapContractAddress, SWAP_ABI, provider);
        const exchangeRate = await swapContract.getExchangeRate();
        const rate = ethers.utils.formatUnits(exchangeRate, 18);
        
        document.getElementById('exchangeRate').textContent = `1 TokenA = ${parseFloat(rate).toFixed(6)} TokenB`;
        document.getElementById('minReceived').textContent = `${parseFloat(amountOut).toFixed(6)} TokenB`;
        
        swapInfo.style.display = 'block';
    } catch (error) {
        console.error('Error updating swap info:', error);
    }
}

async function checkAllowance() {
    if (!userAddress || !tokenAAddress || !swapContractAddress) return;
    
    try {
        const response = await fetch(`${API_URL}/allowance/${tokenAAddress}/${userAddress}/${swapContractAddress}`);
        const data = await response.json();
        
        const tokenContract = new ethers.Contract(tokenAAddress, ERC20_ABI, provider);
        const decimals = await tokenContract.decimals();
        const amount = amountAInput.value;
        const amountIn = ethers.utils.parseUnits(amount, decimals);
        
        if (ethers.BigNumber.from(data.allowance).lt(ethers.BigNumber.from(amountIn))) {
            approveBtn.style.display = 'block';
            swapBtn.disabled = true;
        } else {
            approveBtn.style.display = 'none';
            swapBtn.disabled = false;
        }
    } catch (error) {
        console.error('Error checking allowance:', error);
    }
}

async function approveToken() {
    if (!signer || !tokenAAddress || !swapContractAddress) return;
    
    try {
        showStatus('Approving token...', 'info');
        approveBtn.disabled = true;
        
        const tokenContract = new ethers.Contract(tokenAAddress, ERC20_ABI, signer);
        const decimals = await tokenContract.decimals();
        const amount = amountAInput.value;
        const amountIn = ethers.parseUnits(amount, decimals);
        
        // Approve a large amount for convenience
        const maxApproval = ethers.constants.MaxUint256;
        const tx = await tokenContract.approve(swapContractAddress, maxApproval);
        
        showStatus('Transaction sent. Waiting for confirmation...', 'info');
        await tx.wait();
        
        showStatus('Token approved successfully!', 'success');
        approveBtn.style.display = 'none';
        swapBtn.disabled = false;
        await loadBalances();
    } catch (error) {
        console.error('Error approving token:', error);
        showStatus('Error approving token: ' + error.message, 'error');
    } finally {
        approveBtn.disabled = false;
    }
}

async function executeSwap() {
    if (!signer || !swapContractAddress || !tokenAAddress || !tokenBAddress) {
        showStatus('Please configure contracts and connect wallet', 'error');
        return;
    }
    
    const amount = amountAInput.value;
    if (!amount || parseFloat(amount) <= 0) {
        showStatus('Please enter a valid amount', 'error');
        return;
    }
    
    try {
        showStatus('Executing swap...', 'info');
        swapBtn.disabled = true;
        
        const swapContract = new ethers.Contract(swapContractAddress, SWAP_ABI, signer);
        const tokenAContract = new ethers.Contract(tokenAAddress, ERC20_ABI, provider);
        const tokenBContract = new ethers.Contract(tokenBAddress, ERC20_ABI, provider);
        
        const decimalsA = await tokenAContract.decimals();
        const decimalsB = await tokenBContract.decimals();
        
        const amountIn = ethers.utils.parseUnits(amount, decimalsA);
        const minAmountOut = ethers.utils.parseUnits(amountBInput.value, decimalsB);
        const minAmountOutWithSlippage = minAmountOut.mul(95).div(100); // 5% slippage tolerance
        
        // Determine swap direction
        const tokenAFromSwap = await swapContract.tokenA();
        let tx;
        
        if (tokenAAddress.toLowerCase() === tokenAFromSwap.toLowerCase()) {
            tx = await swapContract.swapAForB(amountIn, minAmountOutWithSlippage);
        } else {
            tx = await swapContract.swapBForA(amountIn, minAmountOutWithSlippage);
        }
        
        showStatus('Transaction sent. Waiting for confirmation...', 'info');
        await tx.wait();
        
        showStatus('Swap completed successfully!', 'success');
        
        // Reset form
        amountAInput.value = '';
        amountBInput.value = '';
        swapInfo.style.display = 'none';
        
        await loadBalances();
    } catch (error) {
        console.error('Error executing swap:', error);
        showStatus('Error executing swap: ' + error.message, 'error');
    } finally {
        swapBtn.disabled = false;
    }
}

async function addLiquidity() {
    if (!signer || !swapContractAddress) {
        showStatus('Please configure contracts and connect wallet', 'error');
        return;
    }
    
    const amountA = document.getElementById('liquidityA').value;
    const amountB = document.getElementById('liquidityB').value;
    
    if (!amountA || !amountB || parseFloat(amountA) <= 0 || parseFloat(amountB) <= 0) {
        showStatus('Please enter valid amounts', 'error');
        return;
    }
    
    try {
        showStatus('Adding liquidity...', 'info');
        addLiquidityBtn.disabled = true;
        
        const swapContract = new ethers.Contract(swapContractAddress, SWAP_ABI, signer);
        const tokenAContract = new ethers.Contract(tokenAAddress, ERC20_ABI, provider);
        const tokenBContract = new ethers.Contract(tokenBAddress, ERC20_ABI, provider);
        
        const decimalsA = await tokenAContract.decimals();
        const decimalsB = await tokenBContract.decimals();
        
        const amountAWei = ethers.utils.parseUnits(amountA, decimalsA);
        const amountBWei = ethers.utils.parseUnits(amountB, decimalsB);
        
        // Approve tokens if needed
        const allowanceA = await tokenAContract.allowance(userAddress, swapContractAddress);
        if (allowanceA.lt(amountAWei)) {
            await tokenAContract.connect(signer).approve(swapContractAddress, ethers.constants.MaxUint256);
        }
        
        const allowanceB = await tokenBContract.allowance(userAddress, swapContractAddress);
        if (allowanceB.lt(amountBWei)) {
            await tokenBContract.connect(signer).approve(swapContractAddress, ethers.constants.MaxUint256);
        }
        
        const tx = await swapContract.addLiquidity(amountAWei, amountBWei);
        showStatus('Transaction sent. Waiting for confirmation...', 'info');
        await tx.wait();
        
        showStatus('Liquidity added successfully!', 'success');
        document.getElementById('liquidityA').value = '';
        document.getElementById('liquidityB').value = '';
        await loadBalances();
    } catch (error) {
        console.error('Error adding liquidity:', error);
        showStatus('Error adding liquidity: ' + error.message, 'error');
    } finally {
        addLiquidityBtn.disabled = false;
    }
}

function handleTokenChange() {
    tokenAAddress = tokenASelect.value;
    tokenBAddress = tokenBSelect.value;
    loadBalances();
    handleAmountChange();
}

function showStatus(message, type) {
    statusMessage.textContent = message;
    statusMessage.className = `status-message ${type}`;
    statusMessage.style.display = 'block';
    
    if (type === 'success' || type === 'error') {
        setTimeout(() => {
            statusMessage.style.display = 'none';
        }, 5000);
    }
}

// Listen for account changes
if (typeof window.ethereum !== 'undefined') {
    window.ethereum.on('accountsChanged', (accounts) => {
        if (accounts.length === 0) {
            disconnectWallet();
        } else {
            connectWallet();
        }
    });
}

} // End of initializeApp function
