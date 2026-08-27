// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./V3Pool.sol";

contract PositionManager is ERC721 {
    V3Pool public immutable pool;

    uint256 public nextTokenId;

    struct Position {
        address token0;
        address token1;
        uint256 liquidity;
        int24 lowerTick;
        int24 upperTick;
    }

    mapping(uint256 => Position) public positions;

    constructor(address _pool)
        ERC721("V3 Liquidity Position", "V3LP")
    {
        pool = V3Pool(_pool);
    }

    function mint(
        uint256 amount0,
        uint256 amount1,
        int24 lowerTick,
        int24 upperTick
    ) external returns (uint256 tokenId) {

        require(
            lowerTick < upperTick,
            "Invalid range"
        );

        require(
            amount0 > 0 || amount1 > 0,
            "No liquidity"
        );

        pool.addLiquidity(
            msg.sender,
            amount0,
            amount1,
            lowerTick,
            upperTick
        );

        tokenId = nextTokenId++;

        positions[tokenId] = Position({
            token0: address(pool.token0()),
            token1: address(pool.token1()),
            liquidity: amount0 + amount1,
            lowerTick: lowerTick,
            upperTick: upperTick
        });

        _mint(msg.sender, tokenId);
    }

    function getPosition(uint256 tokenId)
        external
        view
        returns (Position memory)
    {
        require(
            _ownerOf(tokenId) != address(0),
            "Position does not exist"
        );

        return positions[tokenId];
    }

    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) external {

        require(
            ownerOf(tokenId) == msg.sender,
            "Not position owner"
        );

        require(
            amount0 > 0 || amount1 > 0,
            "No liquidity"
        );

        Position storage position =
            positions[tokenId];

        pool.addLiquidity(
            msg.sender,
            amount0,
            amount1,
            position.lowerTick,
            position.upperTick
        );

        position.liquidity += amount0 + amount1;
    }

    function decreaseLiquidity(
        uint256 tokenId,
        uint256 amount
    ) external {

        require(
            ownerOf(tokenId) == msg.sender,
            "Not position owner"
        );

        require(
            amount > 0,
            "Zero amount"
        );

        require(
            positions[tokenId].liquidity >= amount,
            "Insufficient liquidity"
        );

        positions[tokenId].liquidity -= amount;
    }
}