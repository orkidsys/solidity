# Token Swap Application

A decentralized token swap application with wallet connect integration, built with Solidity, Node.js, and vanilla JavaScript.

## Features

- 🔄 Token-to-token swapping using AMM (Automated Market Maker) model
- 💼 Wallet Connect integration (MetaMask, WalletConnect, etc.)
- 📊 Real-time price quotes and exchange rates
- 💧 Liquidity management (add/remove liquidity)
- 🎨 Modern, responsive UI
- ⚡ Fast swap execution with slippage protection

## Project Structure

```
swap/
├── contracts/
│   └── TokenSwap.sol          # Main swap contract
├── backend/
│   └── server.js              # Express API server
├── frontend/
│   ├── index.html             # Main UI
│   ├── styles.css             # Styling
│   └── app.js                 # Frontend logic
├── package.json               # Node.js dependencies
└── README.md                  # This file
```

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MetaMask or another Web3 wallet
- A local blockchain (Hardhat, Ganache) or testnet access

## Installation

1. Install dependencies:
```bash
npm install
```

2. Configure your RPC URL (optional):
   - Create a `.env` file in the root directory
   - Add: `RPC_URL=http://localhost:8545` (or your preferred RPC endpoint)

## Deployment

### 1. Deploy ERC20 Tokens

First, deploy two ERC20 tokens using the `ERC20Token.sol` contract from the parent directory or create your own.

Example deployment parameters:
- Token A: Name="Token A", Symbol="TKA", Decimals=18, InitialSupply=1000000 * 10^18
- Token B: Name="Token B", Symbol="TKB", Decimals=18, InitialSupply=1000000 * 10^18

### 2. Deploy Swap Contract

Deploy `TokenSwap.sol` with:
- `_tokenA`: Address of first token
- `_tokenB`: Address of second token

### 3. Add Initial Liquidity

After deployment, add liquidity to the swap contract:
- Call `addLiquidity()` with equal or desired amounts of both tokens
- Example: 1000 Token A and 1000 Token B

## Running the Application

1. Start the backend server:
```bash
npm start
```

Or for development with auto-reload:
```bash
npm run dev
```

2. Open the frontend:
   - Open `frontend/index.html` in a browser, or
   - Navigate to `http://localhost:3001` (server serves the frontend)

3. Connect your wallet:
   - Click "Connect Wallet"
   - Approve the connection in MetaMask

4. Configure contracts:
   - Enter the Swap Contract address
   - Enter Token A and Token B addresses
   - Click "Load Configuration"

5. Start swapping:
   - Enter the amount to swap
   - Review the quote
   - Approve token if needed
   - Click "Swap"

## API Endpoints

- `GET /api/token/:address` - Get token information
- `GET /api/balance/:tokenAddress/:userAddress` - Get token balance
- `GET /api/swap/:swapAddress` - Get swap contract info
- `POST /api/swap/quote` - Get swap quote
- `GET /api/allowance/:tokenAddress/:owner/:spender` - Get token allowance
- `GET /api/health` - Health check

## Contract Functions

### TokenSwap.sol

- `swapAForB(amountIn, minAmountOut)` - Swap token A for token B
- `swapBForA(amountIn, minAmountOut)` - Swap token B for token A
- `getAmountOut(tokenIn, amountIn)` - Get expected output amount
- `addLiquidity(amountA, amountB)` - Add liquidity to the pool
- `removeLiquidity(amountA, amountB)` - Remove liquidity (owner only)
- `getReserves()` - Get current reserves
- `getExchangeRate()` - Get current exchange rate

## Security Notes

⚠️ **This is a simplified implementation for educational purposes.**

For production use, consider:
- Using established protocols (Uniswap, SushiSwap)
- Implementing proper access controls
- Adding comprehensive testing
- Security audits
- Reentrancy protection
- More sophisticated AMM formulas

## Troubleshooting

**Wallet not connecting:**
- Ensure MetaMask is installed and unlocked
- Check that you're on the correct network
- Refresh the page and try again

**Swap failing:**
- Ensure you have sufficient token balance
- Check that tokens are approved
- Verify contract addresses are correct
- Ensure sufficient liquidity in the pool

**Backend errors:**
- Verify RPC URL is correct
- Check that contracts are deployed
- Ensure Node.js version is compatible

## License

MIT
