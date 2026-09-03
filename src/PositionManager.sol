// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./V3Pool.sol";

contract PositionManager is ERC721 {
    V3Pool public immutable pool;

    uint256 public nextTokenId;

    struct Position {
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0;
        uint256 amount1;
    }

    mapping(uint256 => Position) public positions;

    constructor(address _pool) ERC721("V3 Liquidity Position", "V3LP") {
        pool = V3Pool(_pool);
    }

    function mint(uint256 amount0, uint256 amount1, int24 lowerTick, int24 upperTick)
        external
        returns (uint256 tokenId)
    {
        require(lowerTick < upperTick, "Invalid range");

        require(amount0 > 0 || amount1 > 0, "No liquidity");

        pool.addLiquidity(msg.sender, amount0, amount1, lowerTick, upperTick);

        tokenId = nextTokenId++;

        positions[tokenId] = Position({
            amount0: amount0, amount1: amount1, lowerTick: lowerTick, upperTick: upperTick, liquidity: amount0 + amount1
        });
        _mint(msg.sender, tokenId);
    }

    function increaseLiquidity(uint256 tokenId, uint256 amount0, uint256 amount1) external {
        require(ownerOf(tokenId) == msg.sender, "Not position owner");

        require(amount0 > 0 || amount1 > 0, "No liquidity");

        Position storage position = positions[tokenId];

        pool.addLiquidity(msg.sender, amount0, amount1, position.lowerTick, position.upperTick);

        position.amount0 += amount0;
        position.amount1 += amount1;
        position.liquidity += amount0 + amount1;
    }

    function decreaseLiquidity(uint256 tokenId, uint256 amount) external {
        require(ownerOf(tokenId) == msg.sender, "Not position owner");

        require(amount > 0, "Zero amount");

        require(positions[tokenId].liquidity >= amount, "Insufficient liquidity");

        positions[tokenId].liquidity -= amount;
    }

    function getPositionValue(uint256 tokenId)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 totalValueInToken1, uint256 currentPrice)
    {
        require(ownerOf(tokenId) != address(0), "Position does not exist");

        Position memory position = positions[tokenId];

        amount0 = position.amount0;
        amount1 = position.amount1;
        currentPrice = pool.currentPrice();

        totalValueInToken1 = (amount0 * currentPrice) + amount1;
    }
}
