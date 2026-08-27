// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MockERC20.sol";

contract V3Pool {
    MockERC20 public immutable token0;
    MockERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public currentPrice;
    uint256 public totalLiquidity;

    struct Position {
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
    }

    mapping(address => Position) public positions;

    constructor(
        address _token0,
        address _token1,
        uint256 _initialPrice
    ) {
        require(_token0 != _token1, "Same token");

        token0 = MockERC20(_token0);
        token1 = MockERC20(_token1);
        currentPrice = _initialPrice;
    }

    function addLiquidity(
        address provider,
        uint256 amount0,
        uint256 amount1,
        int24 lowerTick,
        int24 upperTick
    ) external {
        require(amount0 > 0 || amount1 > 0, "No liquidity");
        require(lowerTick < upperTick, "Invalid range");

        token0.transferFrom(
            provider,
            address(this),
            amount0
        );

        token1.transferFrom(
            provider,
            address(this),
            amount1
        );

        uint256 liquidity = amount0 + amount1;

        reserve0 += amount0;
        reserve1 += amount1;
        totalLiquidity += liquidity;

        positions[provider] = Position({
            liquidity: liquidity,
            lowerTick: lowerTick,
            upperTick: upperTick
        });
    }

    function getPosition(address provider)
        external
        view
        returns (
            uint256 liquidity,
            int24 lowerTick,
            int24 upperTick
        )
    {
        Position memory position = positions[provider];

        return (
            position.liquidity,
            position.lowerTick,
            position.upperTick
        );
    }

    function setPrice(uint256 newPrice) external {
        require(newPrice > 0, "Invalid price");

        currentPrice = newPrice;
    }

    function getReserves()
        external
        view
        returns (uint256, uint256)
    {
        return (reserve0, reserve1);
    }
}