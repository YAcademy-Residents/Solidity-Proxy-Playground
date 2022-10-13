// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Proxy} from      "./TransparentProxy_storageCollisionHack.sol";
import {ProxyFixed} from "./TransparentProxy_storageCollisionHack_fixed.sol";
import {Implementation} from "./Implementation.sol";

interface IProxy {
    function implementation() external returns (address);
    function setBenignAddress(address) external;
    function setImplementation(address) external;
}

contract TransparentProxy_storageCollisionHack is Test {
    address public proxy;
    address public proxyFixed;
    Implementation public implementation;

    address public owner;

    function setUp() public {

        // deploy vulnerable version
        owner = address(0xbabe);
        implementation = new Implementation();
        proxy = address(new Proxy(address(implementation), owner));

        // deploy fixed version
        proxyFixed = address(new Proxy(address(implementation), owner));

    }

    // Here's the hack, if owner calls the very innocent `setBenignAddress`
    // then because the proxy uses the storage on the proxy, this fn will update
    // slot 0 which is the implementation slot on the proxy.
    function testFailProxy_oops() public {
        address implementationAddress = address(implementation);

        address newImplementationAddress = address(0xb0ffed);
        vm.prank(owner);
        IProxy(proxy).setBenignAddress(newImplementationAddress);
        assertEq(IProxy(proxy).implementation(), newImplementationAddress);

        // This will cause revert because this fn is not found on the new implementation
        vm.prank(owner);
        IProxy(proxy).setBenignAddress(address(0x123));

    }

    // Here's the same test on the fixed contract.
    function testProxy_oops_FIXED() public {
        address oldImplementationAddress = address(implementation);
        address newImplementationAddress = address(0xb0ffed);

        // The storage slot 0 no longer collides with the storage slot of the `implementation` address
        vm.prank(owner);
        IProxy(proxyFixed).setBenignAddress(newImplementationAddress);
        assertEq(IProxy(proxyFixed).implementation(), oldImplementationAddress);

        vm.prank(owner);
        IProxy(proxyFixed).setImplementation(newImplementationAddress);
        assertEq(IProxy(proxyFixed).implementation(), newImplementationAddress);

    }

}
