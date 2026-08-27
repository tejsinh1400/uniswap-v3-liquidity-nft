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
        token0 = new MockERC20(
            "Token0",
            "TK0"
        );

        token1 = new MockERC20(
            "Token1",
            "TK1"
        );

        pool = new V3Pool(
            address(token0),
            address(token1),
            3000
        );

        positionManager = new PositionManager(
            address(pool)
        );

        token0.mint(user, 1000);
        token1.mint(user, 2000);
    }

    function testMintPosition() public {
        vm.startPrank(user);

        token0.approve(
            address(pool),
            100
        );

        token1.approve(
            address(pool),
            200
        );

        uint256 tokenId =
            positionManager.mint(
                100,
                200,
                -100,
                100
            );

        vm.stopPrank();

        assertEq(tokenId, 0);

        assertEq(
            positionManager.ownerOf(0),
            user
        );

        (
            address positionToken0,
            address positionToken1,
            uint256 liquidity,
            int24 lowerTick,
            int24 upperTick
        ) = positionManager.positions(0);

        assertEq(
            positionToken0,
            address(token0)
        );

        assertEq(
            positionToken1,
            address(token1)
        );

        assertEq(liquidity, 300);
        assertEq(lowerTick, -100);
        assertEq(upperTick, 100);
    }

    function testIncreaseLiquidity() public {
        vm.startPrank(user);

        token0.approve(
            address(pool),
            500
        );

        token1.approve(
            address(pool),
            500
        );

        uint256 tokenId =
            positionManager.mint(
                100,
                200,
                -100,
                100
            );

        positionManager.increaseLiquidity(
            tokenId,
            50,
            50
        );

        vm.stopPrank();

        (, , uint256 liquidity, , ) =
            positionManager.positions(tokenId);

        assertEq(liquidity, 400);
    }

    function testDecreaseLiquidity() public {
        vm.startPrank(user);

        token0.approve(
            address(pool),
            500
        );

        token1.approve(
            address(pool),
            500
        );

        uint256 tokenId =
            positionManager.mint(
                100,
                200,
                -100,
                100
            );

        positionManager.decreaseLiquidity(
            tokenId,
            100
        );

        vm.stopPrank();

        (, , uint256 liquidity, , ) =
            positionManager.positions(tokenId);

        assertEq(liquidity, 200);
    }
}