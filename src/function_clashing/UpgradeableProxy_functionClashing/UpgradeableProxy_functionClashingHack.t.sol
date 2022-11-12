// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {Proxy} from      "./UpgradeableProxy_functionClashingHack.sol";
import {ProxyFixed} from "./UpgradeableProxy_functionClashingHack_fixed.sol";
import {Implementation} from "./Implementation.sol";

interface IProxy {
    function implementation() external returns (address);
    function doImplementationStuff() external returns (bool);
    function superSafeFunction96508587(address) external;
}

contract UpgradeableProxy_functionClashingHack is Test {
    address payable public proxy;
    address payable public proxyFixed;
    Implementation public implementation;

    address public owner;
    address public admin;

    function setUp() public {

        // deploy vulnerable version
        owner = address(0xbabe);
        implementation = new Implementation();
        proxy = payable(address(new Proxy(address(implementation), owner)));

        // deploy fixed version
        admin = address(0xbeef);
        proxyFixed = payable(address(new ProxyFixed(address(implementation), owner, admin)));

    }

    // Here's the hack, if owner calls the very innocent looking superSafeFunction96508587
    // then Solidity sees that as calling the setImplmentation fn on the proxy.
    function testProxy_oops() public {
        address implementationAddress = address(implementation);
        vm.prank(owner);
        assert(IProxy(proxy).doImplementationStuff());

        address newImplementationAddress = address(0xb0ffed);
        vm.prank(owner);
        IProxy(proxy).superSafeFunction96508587(newImplementationAddress);
        assertEq(IProxy(proxy).implementation(), newImplementationAddress);

    }

    // Here's the same test on the fixed contract.
    function testProxy_oops_FIXED() public {
        address implementationAddress = address(implementation);
        vm.prank(owner);
        assert(IProxy(proxyFixed).doImplementationStuff());

        // Calling the superSafeFunction will still collide with the proxy, but now it is protected
        // by restricting access to admin only.
        address newImplementationAddress = address(0xb0ffed);
        vm.expectRevert(bytes("only admin"));
        vm.prank(owner);
        IProxy(proxyFixed).superSafeFunction96508587(newImplementationAddress);
        assertEq(IProxy(proxyFixed).implementation(), implementationAddress); // still has old implementation

        // This will not cause revert because this fn is not found on the new implementation
        vm.prank(owner);
        IProxy(proxyFixed).doImplementationStuff();

        vm.prank(admin);
        ProxyFixed(proxyFixed).setImplementation(payable(address(0x123)));
        assertEq(Proxy(proxyFixed).implementation(), address(0x123));

    }

}
