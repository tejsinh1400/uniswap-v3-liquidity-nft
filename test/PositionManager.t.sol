// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import "../src/MockERC20.sol";
import "../src/V3Pool.sol";
import "../src/PositionManager.sol";

contract PositionManagerTest is Test {
    MockERC20 token0;
    MockERC20 token1;

    V3Pool pool;
    PositionManager positionManager;

    address user = address(1);

    function setUp() public {
        token0 = new MockERC20("Token0", "TK0");

        token1 = new MockERC20("Token1", "TK1");

        pool = new V3Pool(address(token0), address(token1), 3000);

        positionManager = new PositionManager(address(pool));

        token0.mint(user, 1000);
        token1.mint(user, 2000);
    }

    function testMintPosition() public {
        vm.startPrank(user);

        token0.approve(address(pool), 100);

        token1.approve(address(pool), 200);

        uint256 tokenId = positionManager.mint(100, 200, -100, 100);

        vm.stopPrank();

        assertEq(tokenId, 0);

        assertEq(positionManager.ownerOf(0), user);
        (uint256 liquidity, int24 lowerTick, int24 upperTick, uint256 amount0, uint256 amount1) =
            positionManager.positions(0);

        assertEq(liquidity, 300);
        assertEq(lowerTick, -100);
        assertEq(upperTick, 100);
        assertEq(amount0, 100);
        assertEq(amount1, 200);
    }

    function testIncreaseLiquidity() public {
        vm.startPrank(user);

        token0.approve(address(pool), 500);

        token1.approve(address(pool), 500);

        uint256 tokenId = positionManager.mint(100, 200, -100, 100);

        positionManager.increaseLiquidity(tokenId, 50, 50);

        vm.stopPrank();

        (uint256 liquidity,,,,) = positionManager.positions(tokenId);
        assertEq(liquidity, 400);
    }

    function testDecreaseLiquidity() public {
        vm.startPrank(user);

        token0.approve(address(pool), 500);

        token1.approve(address(pool), 500);

        uint256 tokenId = positionManager.mint(100, 200, -100, 100);

        positionManager.decreaseLiquidity(tokenId, 100);

        vm.stopPrank();

        (uint256 liquidity,,,,) = positionManager.positions(tokenId);

        assertEq(liquidity, 200);
    }

    function testGetPositionValue() public {
        vm.startPrank(user);

        token0.approve(address(pool), 100);
        token1.approve(address(pool), 200);

        uint256 tokenId = positionManager.mint(100, 200, -100, 100);

        (uint256 amount0, uint256 amount1, uint256 totalValueInToken1, uint256 currentPrice) =
            positionManager.getPositionValue(tokenId);

        vm.stopPrank();

        assertEq(amount0, 100);
        assertEq(amount1, 200);
        assertEq(currentPrice, 3000);
        assertEq(totalValueInToken1, 300200);
    }
}
