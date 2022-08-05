// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {TestToken} from "../src/UUPS_Uninitialized/TestToken.sol";

contract UUPS_Uninitialized is Test {
    // These contracts are from https://solidity-by-example.org/hacks/delegatecall/
    TestToken public tokenAddress;

    function setUp() public {
        tokenAddress = new TestToken();
        tokenAddress.initialize();
    }

    function testToken() public {
        uint256 a = 1;
        assertEq(a, 1);
        address deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
        assertEq(deployer, tokenAddress.owner());
    }

}
