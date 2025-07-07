# SimpleSwap DEX 

A simplified Decentralized Exchange (DEX) for a single token pair with two test tokens.

## 🔗 **Deployed Contracts**

This project includes **three main contracts**:

### **Test Tokens**
- **TokenA (OpenZA):** ERC20 token with OpenZeppelin features (Mintable, Burnable, Permit)
- **TokenB (OpenZB):** ERC20 token with OpenZeppelin features (Mintable, Burnable, Permit)

### **DEX Contract** 
- **SimpleSwap:** Implementing basic functionality without fees

## 🚀 **Main Features**

### **Initialization**
```solidity
function initialize(address _tokenA, address _tokenB) external
```
- Sets the unique token pair for the contract
- Auto-initializes on first liquidity addition

### **Add Liquidity**
```solidity
function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

### **Remove Liquidity**
```solidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB)
```

### **Token Swap**
```solidity
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
) external
```

### **Query Functions**
```solidity
function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256)
function getPrice(address tokenA, address tokenB) external view returns (uint256)
function getReserves() external view returns (uint256, uint256)
```



### **Tokens Features**
Both TokenA and TokenB include:
- **Mintable:** Create additional tokens for testing
- **Burnable:** Remove tokens from circulation
- **Permit (EIP-2612):** Gasless approvals
- **OpenZeppelin Security:** Battle-tested, audited code

## 🔧 **Built With**

- **Solidity ^0.8.0**
- **OpenZeppelin Contracts** - Industry standard for secure smart contracts
- **Remix IDE** - Development and testing environment
- **ERC20 Standard** - Token implementation

## ✅ Verification Results

**Contract successfully verified on Sepolia testnet!**

- **Verification Transaction:** [0x3ead4ec194c8e89157b604be78e41a9556fe9dd363dc11daac25b98c5ef06c00](https://sepolia.etherscan.io/tx/0x3ead4ec194c8e89157b604be78e41a9556fe9dd363dc11daac25b98c5ef06c00)
- **Status:** ✅ SUCCESS
- **All DEX functions tested and working correctly**

### Events Logged:
- ✅ LiquidityAdded
- ✅ Swap  
- ✅ LiquidityRemoved