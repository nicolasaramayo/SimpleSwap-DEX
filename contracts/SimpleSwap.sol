// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @title SimpleSwap
 * @notice Un DEX simplificado para un solo par de tokens
 * @dev Implementa funcionalidad  básica
 */
contract SimpleSwap {
    
    // Variables de estado para el par único
    address public tokenA;
    address public tokenB;
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    // Constante para liquidez mínima
    uint256 private constant MINIMUM_LIQUIDITY = 1000;
    
    // Eventos
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    
    /**
     * @notice Inicializa el par de tokens
     * @param _tokenA Dirección del token A
     * @param _tokenB Dirección del token B
     */
    function initialize(address _tokenA, address _tokenB) external {
        require(tokenA == address(0), "Already initialized");
        require(_tokenA != _tokenB, "Identical tokens");
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
    
    
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "Transaction expired");
        require(to != address(0), "Zero address");
        
        // Auto-inicializar si no está inicializado
        if (tokenA == address(0)) {
            require(_tokenA != _tokenB, "Identical tokens");
            require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
            tokenA = _tokenA;
            tokenB = _tokenB;
        } else {
            require(_tokenA == tokenA && _tokenB == tokenB, "Invalid tokens");
        }
        
        // Calcular cantidades
        (amountA, amountB) = _calculateLiquidityAmounts(
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin
        );
        
        // Transferir tokens
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        
        // Calcular liquidez a emitir
        if (totalSupply == 0) {
            liquidity = _sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            balanceOf[address(0)] = MINIMUM_LIQUIDITY; // Lock inicial
        } else {
            liquidity = _min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }
        
        require(liquidity > 0, "Insufficient liquidity");
        
        // Actualizar estado
        balanceOf[to] += liquidity;
        totalSupply += liquidity;
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }


    
   
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "Transaction expired");
        require(_tokenA == tokenA && _tokenB == tokenB, "Invalid tokens");
        require(liquidity > 0, "Invalid amount");
        require(balanceOf[msg.sender] >= liquidity, "Insufficient balance");
        require(to != address(0), "Zero address");
        
        // Calcular cantidades proporcionales
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;
        
        require(amountA >= amountAMin, "Insufficient A amount");
        require(amountB >= amountBMin, "Insufficient B amount");
        
        // Actualizar estado
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transferir tokens
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
        
        emit LiquidityRemoved(to, amountA, amountB, liquidity);
    }
    
    /**
     * @notice Intercambia una cantidad exacta de tokens de entrada por tokens de salida
     * @param amountIn Cantidad de tokens de entrada
     * @param amountOutMin Cantidad mínima de tokens de salida
     * @param path Array de direcciones de tokens [tokenIn, tokenOut]
     * @param to Dirección que recibe los tokens de salida
     * @param deadline Tiempo límite para la transacción
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(block.timestamp <= deadline, "Transaction expired");
        require(amountIn > 0, "Invalid input");
        require(path.length == 2, "Invalid path");
        require(to != address(0), "Zero address");
        
        address tokenIn = path[0];
        address tokenOut = path[1];
        
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");
        require(tokenOut == tokenA || tokenOut == tokenB, "Invalid token");
        require(tokenIn != tokenOut, "Same tokens");
        
        // Determinar reservas
        uint256 reserveIn = tokenIn == tokenA ? reserveA : reserveB;
        uint256 reserveOut = tokenIn == tokenA ? reserveB : reserveA;
        
        // Calcular output usando fórmula x * y = k
        uint256 amountOut = _getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Insufficient output");
        
        // Transferir tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);
        
        // Actualizar reservas
        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
        
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
    
    
    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input");
        require(_tokenIn == tokenA || _tokenIn == tokenB, "Invalid token");
        require(_tokenOut == tokenA || _tokenOut == tokenB, "Invalid token");
        require(_tokenIn != _tokenOut, "Same tokens");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        
        uint256 reserveIn = _tokenIn == tokenA ? reserveA : reserveB;
        uint256 reserveOut = _tokenIn == tokenA ? reserveB : reserveA;
        
        // Fórmula AMM: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }
    
    /**
     * @notice Función interna para calcular output - mantiene funcionalidad existente
     * @param amountIn Cantidad de tokens de entrada
     * @param reserveIn Reserva del token de entrada
     * @param reserveOut Reserva del token de salida
     * @return amountOut Cantidad de tokens de salida
     */
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        
        // Fórmula AMM: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }
    
   
    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require(_tokenA == tokenA && _tokenB == tokenB, "Invalid tokens");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        
        if (_tokenA == tokenA) {
            price = (reserveB * 1e18) / reserveA;
        } else {
            price = (reserveA * 1e18) / reserveB;
        }
    }
    
    /**
     * @notice Obtiene las reservas actuales
     * @return _reserveA Reserva del token A
     * @return _reserveB Reserva del token B
     */
    function getReserves() external view returns (uint256 _reserveA, uint256 _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }
    
    // Funciones internas
    function _calculateLiquidityAmounts(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B amount");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal <= amountADesired && amountAOptimal >= amountAMin, "Insufficient A amount");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
} 